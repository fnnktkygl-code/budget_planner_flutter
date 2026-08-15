export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  let body = req.body || {};
  if (typeof body === 'string') {
    try {
      body = JSON.parse(body);
    } catch (_) {
      body = {};
    }
  }
  const query = req.query || {};

  const grant_type = body.grant_type || query.grant_type || 'authorization_code';
  const client_id = body.client_id || query.client_id;
  const client_secret = body.client_secret || query.client_secret;
  const redirect_uri = body.redirect_uri || query.redirect_uri;
  const code = body.code || query.code;
  const is_sandbox = body.is_sandbox || query.is_sandbox;

  const effectiveClientId = client_id || process.env.TRUELAYER_CLIENT_ID || 'aurabudget-076e60';
  const effectiveClientSecret = client_secret || process.env.TRUELAYER_CLIENT_SECRET || 'tlcs_live_93v3rjwgbbn4_UB8V1f3DirjKcNcGd3uQ0sYboJlBdbLpc1Bstac3rUN8';

  console.log('Received TrueLayer token request:', {
    grant_type,
    client_id: effectiveClientId,
    client_secret: effectiveClientSecret ? 'PROVIDED' : 'MISSING',
    redirect_uri,
    is_sandbox,
  });

  const isSandbox = is_sandbox === 'true' || is_sandbox === true || (effectiveClientId && effectiveClientId.includes('sandbox'));

  const baseUrl = isSandbox
    ? 'https://auth.truelayer-sandbox.com'
    : 'https://auth.truelayer.com';

  const tokenUrl = `${baseUrl}/connect/token`;

  try {
    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: grant_type || 'authorization_code',
        client_id: effectiveClientId,
        client_secret: effectiveClientSecret,
        redirect_uri,
        code,
      }).toString(),
    });

    const data = await response.json();
    res.status(response.status).json(data);
  } catch (error) {
    console.error('Error during token exchange proxy:', error);
    res.status(500).json({ error: 'Internal Server Error', details: error.toString() });
  }
}
