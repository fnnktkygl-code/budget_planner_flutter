/**
 * Smart Gemini & Gemma Quota Rotator — AuraBudget Pro
 */

const MODEL_CASCADE_TIERS = [
  'gemini-3.7-flash',
  'gemini-3.7-flash-lite',
  'gemini-3.5-flash-lite',
  'gemini-3.1-flash-lite',
  'gemini-2.5-flash-lite',
  'gemini-3.5-flash',
  'gemini-3.6-flash',
  'gemini-2.5-flash',
  'gemma-4-31b-it',
  'gemma-4-26b-a4b-it',
  'gemma-2-27b-it',
  'gemini-2.0-flash',
  'gemini-1.5-flash'
];

const modelCooldownMap = new Map();
let lastCallTimestamp = 0;

async function enforcePacingDelay(delayMs = 150) {
  const now = Date.now();
  const elapsed = now - lastCallTimestamp;
  if (elapsed < delayMs) {
    await new Promise((resolve) => setTimeout(resolve, delayMs - elapsed));
  }
  lastCallTimestamp = Date.now();
}

export async function callGeminiApi({ apiKey, prompt, contents, generationConfig, systemInstruction, tools }) {
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is missing');
  }

  let lastErr = null;
  const now = Date.now();

  for (const modelName of MODEL_CASCADE_TIERS) {
    const cooldownUntil = modelCooldownMap.get(modelName) || 0;
    if (now < cooldownUntil) {
      continue;
    }

    try {
      await enforcePacingDelay(150);

      const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

      const bodyPayload = {};
      if (contents) {
        bodyPayload.contents = contents;
      } else if (prompt) {
        bodyPayload.contents = [{ parts: [{ text: prompt }] }];
      }

      if (generationConfig) {
        bodyPayload.generationConfig = generationConfig;
      }

      if (systemInstruction) {
        bodyPayload.systemInstruction = { parts: [{ text: systemInstruction }] };
      }

      if (tools) {
        bodyPayload.tools = tools;
      }

      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(bodyPayload)
      });

      if (!response.ok) {
        const errorBody = await response.json().catch(() => ({}));
        if (response.status === 429) {
          modelCooldownMap.set(modelName, Date.now() + 30 * 1000); // 30s cooldown
          lastErr = new Error(errorBody.error?.message || `Rate limit on ${modelName}`);
          continue;
        }

        if (response.status === 404 || response.status === 400) {
          lastErr = new Error(errorBody.error?.message || `Unavailable ${modelName}`);
          continue;
        }

        throw new Error(errorBody.error?.message || `Gemini API error: ${response.status}`);
      }

      const data = await response.json();
      const generatedText = data.candidates?.[0]?.content?.parts?.[0]?.text;

      if (generatedText) {
        return { text: generatedText, model: modelName };
      }
    } catch (err) {
      lastErr = err;
    }
  }

  modelCooldownMap.clear();
  throw lastErr || new Error('All Gemini model tiers are temporarily busy.');
}
