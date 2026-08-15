export default async function handler(req, res) {
  // CORS Configuration
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // Extract params from body (POST) or query (GET)
  const body = req.body || {};
  const query = req.query || {};

  const authHeader = req.headers['authorization'] || req.headers['Authorization'] || '';
  const tokenFromHeader = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : '';

  const accessToken = body.accessToken || body.access_token || query.accessToken || query.access_token || tokenFromHeader;
  const action = body.action || query.action || 'summary';
  const accountId = body.accountId || body.account_id || query.accountId || query.account_id || '';
  const isSandbox = body.isSandbox === true || body.isSandbox === 'true' || query.isSandbox === 'true';

  if (!accessToken) {
    return res.status(400).json({ error: 'Missing access token' });
  }

  const apiBase = isSandbox
    ? 'https://api.truelayer-sandbox.com/data/v1'
    : 'https://api.truelayer.com/data/v1';

  const authHeaders = {
    Authorization: `Bearer ${accessToken}`,
    Accept: 'application/json',
  };

  try {
    if (action === 'summary') {
      // 1. Fetch Accounts
      const accResponse = await fetch(`${apiBase}/accounts`, { headers: authHeaders });
      if (!accResponse.ok) {
        const errText = await accResponse.text();
        console.error('[TrueLayer Proxy] Accounts error:', accResponse.status, errText);
        return res.status(accResponse.status).json({
          error: `Accounts API error: ${accResponse.status}`,
          details: errText,
        });
      }

      const accData = await accResponse.json();
      const rawAccounts = accData.results || [];
      const accounts = [];
      let primaryCheckingBalance = 0;
      let primaryAccountId = '';
      let providerName = 'BoursoBank';

      for (const rawAcc of rawAccounts) {
        const accId = rawAcc.account_id;
        const displayName = rawAcc.display_name || 'Compte Courant';
        const currency = rawAcc.currency || 'EUR';
        const rawType = (rawAcc.account_type || '').toUpperCase();
        const provDisplayName = rawAcc.provider?.display_name || 'BoursoBank';
        providerName = provDisplayName;

        let currentBal = 0;
        let availableBal = 0;
        let updateTimestamp = new Date().toISOString();

        // Fetch balance for account
        try {
          const balResponse = await fetch(`${apiBase}/accounts/${accId}/balance`, { headers: authHeaders });
          if (balResponse.ok) {
            const balData = await balResponse.json();
            const balResult = balData.results?.[0];
            if (balResult) {
              currentBal = Number(balResult.current ?? 0);
              availableBal = Number(balResult.available ?? currentBal);
              updateTimestamp = balResult.update_timestamp || updateTimestamp;
            }
          }
        } catch (balErr) {
          console.warn(`[TrueLayer Proxy] Failed to fetch balance for account ${accId}:`, balErr);
        }

        const accountObj = {
          account_id: accId,
          display_name: displayName,
          account_type: rawAcc.account_type || 'TRANSACTION',
          currency: currency,
          current_balance: currentBal,
          available_balance: availableBal,
          balance: availableBal !== 0 ? availableBal : currentBal,
          update_timestamp: updateTimestamp,
          provider: rawAcc.provider || { display_name: provDisplayName },
          account_number: rawAcc.account_number,
        };

        accounts.push(accountObj);

        // Select primary account
        if (
          !primaryAccountId ||
          rawType === 'TRANSACTION' ||
          rawType === 'CURRENT' ||
          rawType.includes('CHECKING')
        ) {
          primaryAccountId = accId;
          primaryCheckingBalance = availableBal !== 0 ? availableBal : currentBal;
        }
      }

      // Also fetch cards if accounts is empty or cards exist
      try {
        const cardsResponse = await fetch(`${apiBase}/cards`, { headers: authHeaders });
        if (cardsResponse.ok) {
          const cardsData = await cardsResponse.json();
          const rawCards = cardsData.results || [];
          for (const rawCard of rawCards) {
            const cardId = rawCard.account_id || rawCard.card_id;
            if (accounts.some((a) => a.account_id === cardId)) continue;

            let currentBal = 0;
            let availableBal = 0;
            try {
              const cardBalRes = await fetch(`${apiBase}/cards/${cardId}/balance`, { headers: authHeaders });
              if (cardBalRes.ok) {
                const cardBalData = await cardBalRes.json();
                const balResult = cardBalData.results?.[0];
                if (balResult) {
                  currentBal = Number(balResult.current ?? 0);
                  availableBal = Number(balResult.available ?? currentBal);
                }
              }
            } catch {}

            const displayName = rawCard.display_name || `Carte BoursoBank ${rawCard.card_type || ''}`;
            const cardObj = {
              account_id: cardId,
              display_name: displayName,
              account_type: 'TRANSACTION',
              currency: rawCard.currency || 'EUR',
              current_balance: currentBal,
              available_balance: availableBal,
              balance: availableBal !== 0 ? availableBal : currentBal,
              update_timestamp: new Date().toISOString(),
              provider: rawCard.provider || { display_name: 'BoursoBank' },
            };
            accounts.push(cardObj);

            if (!primaryAccountId) {
              primaryAccountId = cardId;
              primaryCheckingBalance = cardObj.balance;
            }
          }
        }
      } catch {}

      // Fetch transactions for primary account if available
      let transactions = [];
      if (primaryAccountId) {
        try {
          const txResponse = await fetch(`${apiBase}/accounts/${primaryAccountId}/transactions`, { headers: authHeaders });
          if (txResponse.ok) {
            const txData = await txResponse.json();
            transactions = txData.results || [];
          }
        } catch (txErr) {
          console.warn('[TrueLayer Proxy] Transactions fetch error:', txErr);
        }
      }

      return res.status(200).json({
        success: true,
        accounts,
        primaryAccountId,
        primaryCheckingBalance,
        providerName,
        transactions,
        timestamp: new Date().toISOString(),
      });
    }

    if (action === 'accounts') {
      const response = await fetch(`${apiBase}/accounts`, { headers: authHeaders });
      const data = await response.json();
      return res.status(response.status).json(data);
    }

    if (action === 'balance') {
      if (!accountId) {
        return res.status(400).json({ error: 'Missing accountId' });
      }
      const response = await fetch(`${apiBase}/accounts/${accountId}/balance`, { headers: authHeaders });
      const data = await response.json();
      return res.status(response.status).json(data);
    }

    if (action === 'transactions') {
      if (!accountId) {
        return res.status(400).json({ error: 'Missing accountId' });
      }
      const response = await fetch(`${apiBase}/accounts/${accountId}/transactions`, { headers: authHeaders });
      const data = await response.json();
      return res.status(response.status).json(data);
    }

    return res.status(400).json({ error: `Unknown action: ${action}` });
  } catch (error) {
    console.error('[TrueLayer Proxy] Handler exception:', error);
    return res.status(500).json({ error: 'Internal server error', details: error.toString() });
  }
}
