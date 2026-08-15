import { callGeminiApi } from './_geminiFallback.js';

export const config = {
  runtime: 'nodejs',
  maxDuration: 30,
};

function fallbackHeuristicClean(transactions) {
  return transactions.map((t) => {
    let name = (t.title || '').toUpperCase();
    name = name.replace(/^(PRLV\s+SEPA|VIR\s+SEPA|PRLV|VIR|CB|PAIEMENT|FACTURE|RETRAIT|CARTE)\s*(\d\d\/\d\d)?\s*/i, '');
    name = name.replace(/,\s*(CACP|RUM|REF|EMETTEUR|ID|CONTRAT|FACTURE|TIERS|DOSSIER|\d{4,}).*$/i, '');
    name = name.replace(/\b(CACP|RUM|REF|EMETTEUR|ID|NOT|CONTRAT|FACTURE|DOSSIER|TIERS)\s*[:.\s]\s*\S+.*$/i, '');
    name = name.replace(/\b04375[A-Z0-9]+\b.*$/i, '');
    name = name.replace(/\b719754[A-Z0-9]+\b.*$/i, '');
    name = name.replace(/\bCB\*\d+\b/i, '');
    name = name.replace(/\bCARTE\s+X+\d+\b/i, '');
    name = name.replace(/\d\d\/\d\d(\/\d{2,4})?/g, '');
    name = name.replace(/[-_/]/g, ' ').replace(/\s+/g, ' ').trim();

    let cleanMerchant = name;
    let canonicalGroupKey = name.toLowerCase().replace(/[^a-z0-9]/g, '');
    let category = 'Abonnement / Charge';
    let suggestedType = 'charge_fixe';
    let suggestedDurationMonths = 12;
    let reason = 'Prélèvement automatique régulier identifié.';

    if (name.includes('CDC HABITAT')) {
      cleanMerchant = 'CDC Habitat (Loyer / Logement)';
      canonicalGroupKey = 'cdc_habitat';
      category = 'Logement / Loyer';
      reason = 'Prélèvement mensuel pour votre loyer / logement.';
    } else if (name.includes('TURREL')) {
      cleanMerchant = 'Turrel Baptiste';
      canonicalGroupKey = 'turrel_baptiste';
      category = 'Abonnement / Charge';
      reason = 'Prélèvement régulier récurrent.';
    } else if (name.includes('BPCE')) {
      cleanMerchant = 'BPCE Assurances (Habitation)';
      canonicalGroupKey = 'bpce_assurances';
      category = 'Assurance Habitation';
      reason = 'Cotisation d\'assurance habitation mensuelle.';
    } else if (name.includes('SENDWAVE')) {
      cleanMerchant = 'Sendwave';
      canonicalGroupKey = 'sendwave';
      category = 'Transfert d\'argent';
      reason = 'Paiement ou transfert ponctuel / récurrent.';
    } else if (name.includes('LATTES') || name.includes('ORTHO') || name.includes('DENT')) {
      cleanMerchant = 'Orthodontie Lattes';
      canonicalGroupKey = 'lattes_ortho';
      category = 'Santé & Soins';
      suggestedType = 'echeance_temporaire';
      suggestedDurationMonths = 3;
      reason = 'Traitement d\'orthodontie / soins de santé étalables.';
    } else if (name.includes('BOUYGUES')) {
      cleanMerchant = 'Bouygues Telecom';
      canonicalGroupKey = 'bouygues_telecom';
      category = 'Télécom & Internet';
      reason = 'Forfait mobile / Box internet.';
    } else if (name.includes('TOTALENERGIES')) {
      cleanMerchant = 'TotalEnergies';
      canonicalGroupKey = 'totalenergies';
      category = 'Énergie & Électricité';
      reason = 'Facture mensuelle d\'énergie.';
    } else if (name.includes('PAYPAL')) {
      cleanMerchant = 'PayPal';
      canonicalGroupKey = 'paypal';
      category = 'Paiement / Abonnement';
      reason = 'Abonnement ou paiement récurrent en ligne.';
    } else if (name.includes('DGFIP') || name.includes('TRESOR') || name.includes('IMPOT')) {
      cleanMerchant = 'DGFIP (Impôts & Taxes)';
      canonicalGroupKey = 'dgfip';
      category = 'Impôts & Taxes';
      suggestedType = 'echeance_temporaire';
      suggestedDurationMonths = 4;
      reason = 'Prélèvement fiscal / impôt sur le revenu.';
    }

    return {
      id: t.id,
      cleanMerchant,
      canonicalGroupKey,
      category,
      suggestedType,
      suggestedDurationMonths,
      reason,
    };
  });
}

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

  const { transactions } = req.body || {};
  if (!transactions || !Array.isArray(transactions) || transactions.length === 0) {
    return res.status(400).json({ error: 'transactions array is required' });
  }

  const apiKey = process.env.GEMINI_API_KEY_MASTER || process.env.GEMINI_API_KEY;

  if (!apiKey) {
    return res.status(200).json({
      success: true,
      modelUsed: 'heuristic-cleaner-fallback',
      cleanedTransactions: fallbackHeuristicClean(transactions),
    });
  }

  try {
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
      "cleanMerchant": "Nom commercial ultra-propre (Ex: CDC Habitat (Loyer), Turrel Baptiste, BPCE Assurances (Habitation), Bouygues Telecom, TotalEnergies, Sendwave, Orthodontie Lattes, PayPal, DGFIP (Impôts)...)",
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
    console.error('Gemini API call failed, falling back to heuristic clean:', error);
    return res.status(200).json({
      success: true,
      modelUsed: 'heuristic-cleaner-fallback',
      cleanedTransactions: fallbackHeuristicClean(transactions),
    });
  }
}
