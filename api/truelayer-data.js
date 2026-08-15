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
  let body = req.body || {};
  if (typeof body === 'string') {
    try {
      body = JSON.parse(body);
    } catch (_) {
      body = {};
    }
  }
  const query = req.query || {};

  const authHeader = req.headers['authorization'] || req.headers['Authorization'] || '';
  const tokenFromHeader = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : '';

  const accessToken = body.accessToken || body.access_token || query.accessToken || query.access_token || tokenFromHeader;
  const action = body.action || query.action || 'summary';
  const accountId = body.accountId || body.account_id || query.accountId || query.account_id || '';
  const isSandbox = body.isSandbox === true || body.isSandbox === 'true' || query.isSandbox === 'true';

  console.log('[TrueLayer Data API] Request received:', {
    action,
    isSandbox,
    hasToken: !!accessToken,
    tokenPrefix: accessToken ? `${accessToken.substring(0, 8)}...` : 'none',
  });

  if (!accessToken) {
    return res.status(400).json({ success: false, error: 'Missing access token' });
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
      const accounts = [];
      const partialErrors = [];
      let providerName = 'BoursoBank';

      // 1. Fetch Accounts
      let rawAccounts = [];
      try {
        const accResponse = await fetch(`${apiBase}/accounts`, { headers: authHeaders });
        const accText = await accResponse.text();
        console.log('[TrueLayer Data] /accounts response status:', accResponse.status, 'body preview:', accText.substring(0, 300));
        
        if (accResponse.ok) {
          const accData = JSON.parse(accText);
          rawAccounts = accData.results || [];
        } else {
          partialErrors.push(`Accounts API (${accResponse.status}): ${accText}`);
        }
      } catch (e) {
        console.error('[TrueLayer Data] Accounts fetch exception:', e);
        partialErrors.push(`Accounts exception: ${e.message || e}`);
      }

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
              currentBal = (balResult.current !== undefined && balResult.current !== null)
                ? Number(balResult.current)
                : ((balResult.available !== undefined && balResult.available !== null) ? Number(balResult.available) : 0);
              availableBal = (balResult.available !== undefined && balResult.available !== null)
                ? Number(balResult.available)
                : currentBal;
              updateTimestamp = balResult.update_timestamp || updateTimestamp;
            }
          } else {
            const balErrText = await balResponse.text();
            console.warn(`[TrueLayer Data] Balance for ${accId} failed (${balResponse.status}):`, balErrText);
          }
        } catch (balErr) {
          console.warn(`[TrueLayer Data] Failed to fetch balance for account ${accId}:`, balErr);
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

      // 2. Also fetch cards if available
      try {
        const cardsResponse = await fetch(`${apiBase}/cards`, { headers: authHeaders });
        const cardsText = await cardsResponse.text();
        console.log('[TrueLayer Data] /cards response status:', cardsResponse.status, 'body preview:', cardsText.substring(0, 300));
        
        if (cardsResponse.ok) {
          const cardsData = JSON.parse(cardsText);
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
      } catch (cardErr) {
        console.warn('[TrueLayer Data] Cards fetch error:', cardErr);
      }

      // Smart selection of primary checking account
      let primaryAccount = accounts.find((a) =>
        a.category === 'checking' &&
        (a.iban_masked.includes('0429') ||
         a.display_name.toLowerCase().includes('richard') ||
         a.display_name.toLowerCase().includes('courant') ||
         a.display_name.toLowerCase().includes('bancaire'))
      );

      if (!primaryAccount) {
        primaryAccount = accounts.find((a) => a.category === 'checking');
      }

      if (!primaryAccount) {
        primaryAccount = accounts.find(
          (a) => a.category !== 'tontine' && a.category !== 'tampon' && a.category !== 'savings' && a.category !== 'investment'
        );
      }

      if (!primaryAccount || primaryAccount.current_balance === 0) {
        const nonZeroAcc = accounts.find((a) => a.category !== 'tontine' && a.category !== 'savings' && a.current_balance > 0);
        if (nonZeroAcc) {
          primaryAccount = nonZeroAcc;
        }
      }

      if (!primaryAccount && accounts.length > 0) {
        primaryAccount = accounts[0];
      }

      let primaryAccountId = '';
      let primaryCheckingBalance = 0;

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
          console.warn('[TrueLayer Data] Transactions fetch error:', txErr);
        }
      }

      console.log(`[TrueLayer Data API] Summary completed: ${accounts.length} accounts found, primaryBalance: ${primaryCheckingBalance} EUR`);

      return res.status(200).json({
        success: accounts.length > 0,
        accounts,
        primaryAccountId,
        primaryCheckingBalance,
        providerName,
        transactions,
        partialErrors,
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
    return res.status(500).json({ success: false, error: 'Internal server error', details: error.toString() });
  }
}
