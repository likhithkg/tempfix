const express = require('express');
const { generateResponse } = require('../services/groq_service');

const router = express.Router();

const MAX_MESSAGE_LENGTH = 2000;
const MAX_HISTORY_MESSAGES = 20;

// POST /api/chat
router.post('/', async (req, res) => {
  const reqId = Date.now().toString(36);
  const t0 = Date.now();

  try {
    const {
      message,
      history = [],
      language = 'en',
      context = null,
    } = req.body;

    // ── Validate ──────────────────────────────────────────────────────────────

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ success: false, error: 'message field is required.' });
    }

    const trimmed = message.trim();

    if (!trimmed) {
      return res.status(400).json({ success: false, error: 'Message cannot be empty.' });
    }

    if (trimmed.length > MAX_MESSAGE_LENGTH) {
      return res.status(400).json({
        success: false,
        error: `Message too long. Maximum ${MAX_MESSAGE_LENGTH} characters allowed.`,
      });
    }

    // Limit and sanitise history
    const safeHistory = (Array.isArray(history) ? history : [])
      .slice(-MAX_HISTORY_MESSAGES)
      .filter(m => m && typeof m.role === 'string' && typeof m.content === 'string');

    console.log(`[${reqId}] recv msg_len=${trimmed.length} history=${safeHistory.length} lang=${language}`);

    // ── Call Groq ─────────────────────────────────────────────────────────────

    const reply = await generateResponse(trimmed, safeHistory, language, context || null);

    const latency = Date.now() - t0;
    console.log(`[${reqId}] ok latency=${latency}ms reply_len=${reply.length}`);

    return res.status(200).json({ success: true, message: reply });

  } catch (err) {
    const latency = Date.now() - t0;
    console.error(`[${reqId}] error latency=${latency}ms:`, err.message || err);

    // Groq model not found
    if (err.status === 404 || String(err.message).includes('model_not_found')) {
      return res.status(500).json({
        success: false,
        error: 'AI model unavailable. Set GROQ_MODEL in km_chatbot_backend/.env to a valid Groq model.',
      });
    }

    // Groq rate limit
    if (err.status === 429 || String(err.message).includes('rate_limit')) {
      return res.status(429).json({
        success: false,
        error: 'AI service is busy right now. Please try again in a moment.',
      });
    }

    return res.status(500).json({
      success: false,
      error: 'Unable to generate a response. Please try again.',
    });
  }
});

module.exports = router;
