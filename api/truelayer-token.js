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

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const {
    grant_type,
    client_id,
    client_secret,
    redirect_uri,
    code,
    is_sandbox,
  } = req.body;

  const baseUrl = is_sandbox === 'true' || is_sandbox === true
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
        grant_type,
        client_id,
        client_secret,
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
