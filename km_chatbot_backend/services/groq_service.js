const Groq = require('groq-sdk');

// ── Singleton client ──────────────────────────────────────────────────────────

let _client = null;

function getClient() {
  if (!process.env.GROQ_API_KEY) {
    throw new Error('GROQ_API_KEY is missing from km_chatbot_backend/.env');
  }
  if (!_client) {
    _client = new Groq({ apiKey: process.env.GROQ_API_KEY });
  }
  return _client;
}

function getModel() {
  return process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';
}

// ── System prompt ─────────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `You are KrishiMithra AI, an agriculture-focused assistant for Indian farmers.

You specialize in:
- Crop cultivation: rice, wheat, maize, cotton, sugarcane, sunflower, groundnut, coconut, mango, tomato, onion, potato, brinjal, chilli, vegetables, spices, and other Indian crops
- Crop disease identification and treatment
- Pest and weed management
- Irrigation techniques (drip, sprinkler, flood, furrow)
- Soil health, soil testing, and soil fertility improvement
- Fertilizer recommendations (NPK, organic, bio-fertilizers, micronutrients)
- Weather-related farming guidance and climate adaptation
- Indian government agricultural schemes (PM-KISAN, PMFBY, Soil Health Card, etc.)
- Farm machinery, equipment rental, and mechanization
- Labour management and hiring
- Agricultural market prices and trade
- Karnataka agriculture (focus when location is relevant)

Guidelines:
- Give practical, actionable advice that a farmer can follow today
- Use simple, clear language — avoid jargon
- When giving fertilizer or pesticide advice, mention following the product label and consulting a local agricultural officer
- Do not invent statistics or fake data — if you don't know, say so clearly
- Use bullet points for step-by-step guidance
- Keep answers concise but complete
- If asked about crops or topics outside agriculture, politely redirect to farming topics`;

// ── Language instruction ──────────────────────────────────────────────────────

const LANGUAGE_NAMES = {
  hi: 'Hindi',
  kn: 'Kannada',
  ta: 'Tamil',
  te: 'Telugu',
  mr: 'Marathi',
  en: 'English',
};

// ── Main function ─────────────────────────────────────────────────────────────

/**
 * @param {string} userMessage   - Current user message
 * @param {Array}  history       - [{role:'user'|'assistant', content:string}]
 * @param {string} language      - Language code: en|hi|kn|ta|te|mr
 * @param {string|null} context  - Optional KB context string
 */
async function generateResponse(userMessage, history = [], language = 'en', context = null) {
  const client = getClient();
  const model = getModel();

  const messages = [];

  // 1. System prompt
  messages.push({ role: 'system', content: SYSTEM_PROMPT });

  // 2. Language instruction
  if (language && language !== 'en') {
    const langName = LANGUAGE_NAMES[language] || 'English';
    messages.push({
      role: 'system',
      content: `IMPORTANT: The farmer is communicating in ${langName}. Always respond in ${langName}.`,
    });
  }

  // 3. Knowledge-base context (if a KB entry matched)
  if (context && context.trim().length > 0) {
    messages.push({
      role: 'system',
      content: `The following information is from the KrishiMithra knowledge base. Use it as your primary reference:\n\n${context}`,
    });
  }

  // 4. Conversation history (recent messages for follow-up context)
  const safeHistory = Array.isArray(history) ? history : [];
  for (const msg of safeHistory) {
    if (msg.role && msg.content) {
      messages.push({ role: msg.role, content: String(msg.content) });
    }
  }

  // 5. Current user message
  messages.push({ role: 'user', content: userMessage });

  console.log(`[Groq] model=${model} totalMsgs=${messages.length} lang=${language} hasCtx=${!!context}`);

  const completion = await client.chat.completions.create({
    model,
    messages,
    temperature: 0.4,
    max_tokens: 800,
  });

  const reply = completion.choices?.[0]?.message?.content?.trim() || '';
  console.log(`[Groq] reply_len=${reply.length}`);
  return reply;
}

module.exports = { generateResponse };
