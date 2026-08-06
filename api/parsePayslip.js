import { callGeminiApi } from './_geminiFallback.js';

export default async function handler(req, res) {
  // CORS Configuration
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  // Handle OPTIONS request for CORS
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { base64Data, mimeType, rawTextContent } = req.body;
  const apiKey = req.body.apiKey || process.env.GEMINI_API_KEY_MASTER || process.env.GEMINI_API_KEY;

  if (!apiKey) {
    res.status(400).json({ error: 'GEMINI_API_KEY missing in environment' });
    return;
  }

  const prompt = `Tu es un expert comptable spécialisé dans la paie française. Analyse ce bulletin et renvoie STRICTEMENT un JSON valide :
{
  "period": "YYYY-MM", (ex: "2026-07" ou "2026-03")
  "grossSalary": double, (Total salaire brut)
  "netSocial": double, (Montant Net Social)
  "netPayable": double, (STRICTEMENT le Salaire Net VERSÉ sur le compte bancaire APRÈS IMPÔT SUR LE REVENU / Prélèvement à la source. NE PRENDS PAS le Net avant impôt !)
  "hasExplicitBonus": boolean, (true uniquement si une ligne de PRIME DE VACANCES, 13EME MOIS, BONUS ou PRIME EXCEPTIONNELLE est présente)
  "bonusDescription": String (Intitulé exact de la prime si présente, sinon null)
}`;

  try {
    const parts = [{ text: prompt }];

    if (rawTextContent) {
      parts.push({ text: `Texte extrait du document PDF :\n${rawTextContent}` });
    }

    if (base64Data && mimeType) {
      parts.push({
        inline_data: {
          mime_type: mimeType,
          data: base64Data,
        },
      });
    }

    const aiResult = await callGeminiApi({
      apiKey,
      prompt,
      contents: [{ parts }],
      generationConfig: {
        response_mime_type: 'application/json',
      },
    });

    if (aiResult && aiResult.text) {
      const jsonMap = JSON.parse(aiResult.text);
      res.status(200).json(jsonMap);
    } else {
      res.status(500).json({ error: 'Failed to parse payslip via AI' });
    }
  } catch (err) {
    console.error('API parsePayslip error:', err);
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
}
