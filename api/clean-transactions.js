import { callGeminiApi } from './_geminiFallback.js';

export const config = {
  runtime: 'nodejs',
  maxDuration: 30,
};

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: 'GEMINI_API_KEY environment variable is not configured' });
  }

  try {
    const { transactions } = req.body || {};
    if (!transactions || !Array.isArray(transactions) || transactions.length === 0) {
      return res.status(400).json({ error: 'transactions array is required' });
    }

    const rawList = transactions.slice(0, 30).map((t) => ({
      id: t.id,
      title: t.title,
      amount: t.amount,
      date: t.date || null,
    }));

    const prompt = `
Tu es un expert bancaire et comptable français. Ta mission est de normaliser, nettoyer et catégoriser avec élégance des libellés de transactions bancaires françaises brutes (SEPA, CB, Prélèvements STET de BoursoBank).

Voici la liste des transactions brutes :
${JSON.stringify(rawList, null, 2)}

Pour chaque transaction, renvoie STRICTEMENT un objet JSON dans la liste "cleanedTransactions" :
{
  "cleanedTransactions": [
    {
      "id": "id_de_la_transaction",
      "cleanMerchant": "Nom commercial ultra-propre (Ex: CDC Habitat, Turrel Baptiste, BPCE Assurances, Bouygues Telecom, TotalEnergies, Sendwave, Orthodontie Lattes, PayPal, DGFIP...)",
      "canonicalGroupKey": "clé_canonique_unique_pour_regrouper_les_doublons_mensuels (ex: cdc_habitat, turrel_baptiste, bpce_assurances, bouygues_telecom, totalenergies, sendwave, lattes_ortho, paypal, dgfip)",
      "category": "Catégorie claire (ex: Logement / Loyer, Assurance Habitation, Télécom & Internet, Énergie & Gaz, Santé & Soins, Transfert, Abonnement, Impôts & Taxes)",
      "suggestedType": "charge_fixe" ou "echeance_temporaire",
      "suggestedDurationMonths": 12 pour abonnement/charge récurrente, ou 3 à 6 pour soins de santé/paiement fractionné 3x/4x,
      "reason": "Courte explication en français naturel sans code technique (Ex: Loyer ou charges de logement mensuelles, Forfait téléphonique et internet, Assurance habitation prélevée mensuellement, etc.)"
    }
  ]
}

RÈGLES STRICTES :
1. SUPPRIME TOUS LES CODES TECHNIQUES, RUM, CACP, NUMÉROS DE DOSSIER OU DE CARTE (ex: "Cacp.322855169.4", "04375n2202670801689910", "Rum 7tmcm0596bdtw8", "Cb*2753", "719754402zz").
2. Les transactions du même émetteur d'un mois sur l'autre (ex: 3 prélèvements CDC Habitat avec des numéros de facture différents) DOIVENT avoir exactement le même "canonicalGroupKey" et le même "cleanMerchant" afin d'être regroupées.
3. Rends les noms lisibles, professionnels et soignés.
`;

    const { text, model } = await callGeminiApi({
      apiKey,
      prompt,
      generationConfig: {
        response_mime_type: 'application/json',
      },
    });

    const parsed = JSON.parse(text);
    return res.status(200).json({
      success: true,
      modelUsed: model,
      cleanedTransactions: parsed.cleanedTransactions || parsed,
    });
  } catch (error) {
    console.error('Error cleaning transactions with Gemini:', error);
    return res.status(500).json({
      error: error.message || 'Failed to process transactions with Gemini',
    });
  }
}
