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
        const displayName = rawAcc.display_name || 'Compte BoursoBank';
        const currency = rawAcc.currency || 'EUR';
        const rawType = (rawAcc.account_type || '').toUpperCase();
        const provDisplayName = rawAcc.provider?.display_name || 'BoursoBank';
        providerName = provDisplayName;

        const iban = rawAcc.account_number?.iban || '';
        const ibanMasked = iban ? `••••${iban.slice(-4)}` : (rawAcc.account_number?.number ? `••••${rawAcc.account_number.number.slice(-4)}` : '');

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
              currentBal = (balResult.current !== undefined && balResult.current !== null) ? Number(balResult.current) : 0;
              availableBal = (balResult.available !== undefined && balResult.available !== null) ? Number(balResult.available) : currentBal;
              updateTimestamp = balResult.update_timestamp || updateTimestamp;
            }
          }
        } catch (balErr) {
          console.warn(`[TrueLayer Proxy] Failed to fetch balance for account ${accId}:`, balErr);
        }

        // Smart categorization based on BoursoBank IBAN / naming patterns
        let category = 'checking';
        const lowerName = displayName.toLowerCase();
        if (ibanMasked.includes('4455') || lowerName.includes('tampon') || lowerName.includes('autre')) {
          category = 'tampon';
        } else if (ibanMasked.includes('4424') || lowerName.includes('tontine') || lowerName.includes('ou o')) {
          category = 'tontine';
        } else if (lowerName.includes('livret') || lowerName.includes('epargne') || lowerName.includes('saving')) {
          category = 'savings';
        } else if (lowerName.includes('pea') || lowerName.includes('titre') || lowerName.includes('invest') || lowerName.includes('bourse')) {
          category = 'investment';
        } else if (ibanMasked.includes('0429') || lowerName.includes('richard') || lowerName.includes('courant') || lowerName.includes('bancaire')) {
          category = 'checking';
        } else if (rawType === 'TRANSACTION' || rawType === 'CURRENT') {
          category = 'checking';
        } else {
          category = 'other';
        }

        const accountObj = {
          account_id: accId,
          display_name: displayName,
          account_type: rawAcc.account_type || 'TRANSACTION',
          category: category,
          currency: currency,
          current_balance: currentBal,
          available_balance: availableBal,
          balance: currentBal,
          iban_masked: ibanMasked,
          update_timestamp: updateTimestamp,
          provider: rawAcc.provider || { display_name: provDisplayName },
          account_number: rawAcc.account_number,
        };

        accounts.push(accountObj);
      }

      // Also fetch cards if available
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
                  currentBal = (balResult.current !== undefined && balResult.current !== null) ? Number(balResult.current) : 0;
                  availableBal = (balResult.available !== undefined && balResult.available !== null) ? Number(balResult.available) : currentBal;
                }
              }
            } catch {}

            const displayName = rawCard.display_name || `Carte BoursoBank ${rawCard.card_type || ''}`;
            const cardObj = {
              account_id: cardId,
              display_name: displayName,
              account_type: 'TRANSACTION',
              category: 'card',
              currency: rawCard.currency || 'EUR',
              current_balance: currentBal,
              available_balance: availableBal,
              balance: currentBal,
              iban_masked: '',
              update_timestamp: new Date().toISOString(),
              provider: rawCard.provider || { display_name: 'BoursoBank' },
            };
            accounts.push(cardObj);
          }
        }
      } catch {}

      // Smart selection of primary checking account
      // 1. Explicit main checking account (IBAN 0429 or named Richard / Courant / Bancaire)
      let primaryAccount = accounts.find((a) =>
        a.category === 'checking' &&
        (a.iban_masked.includes('0429') ||
         a.display_name.toLowerCase().includes('richard') ||
         a.display_name.toLowerCase().includes('courant') ||
         a.display_name.toLowerCase().includes('bancaire'))
      );

      // 2. Any checking account (excluding tontine, tampon, savings)
      if (!primaryAccount) {
        primaryAccount = accounts.find((a) => a.category === 'checking');
      }

      // 3. Any account that is not tontine, tampon, or savings
      if (!primaryAccount) {
        primaryAccount = accounts.find(
          (a) => a.category !== 'tontine' && a.category !== 'tampon' && a.category !== 'savings' && a.category !== 'investment'
        );
      }

      // 4. First account in list
      if (!primaryAccount && accounts.length > 0) {
        primaryAccount = accounts[0];
      }

      if (primaryAccount) {
        primaryAccountId = primaryAccount.account_id;
        primaryCheckingBalance = primaryAccount.current_balance;
      }

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
