export default async function handler(req, res) {
  // CORS Configuration
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { base64Data, mimeType, rawTextContent } = req.body;

  try {
    const response = await fetch('https://resume-teal-omega.vercel.app/api/parse', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        mode: 'payslip',
        text: rawTextContent,
        base64Data,
        mimeType,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      res.status(200).json(data);
    } else {
      const errText = await response.text();
      console.error('AI Gateway error:', errText);
      res.status(500).json({ error: 'AI Gateway error: ' + errText });
    }
  } catch (err) {
    console.error('API parsePayslip error:', err);
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
}
