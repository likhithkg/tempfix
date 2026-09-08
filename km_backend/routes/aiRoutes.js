'use strict';

const express = require('express');
const router = express.Router();

const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';
const HF_DISEASE_MODEL =
  'linkanjarad/plant-disease-classification-mobilenet_v2_0.35_224';

// ── POST /api/ai/gemini/generate ─────────────────────────────────────────────
// Body: { model?, contents, systemInstruction?, generationConfig? }
// Returns: { text } | { error }
router.post('/gemini/generate', async (req, res) => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'Gemini API not configured on server' });

  const {
    model = 'gemini-2.5-flash',
    contents,
    systemInstruction,
    generationConfig = { temperature: 0.7, maxOutputTokens: 1024 },
  } = req.body;

  if (!Array.isArray(contents) || contents.length === 0) {
    return res.status(400).json({ error: '`contents` array is required' });
  }

  const payload = { contents, generationConfig };
  if (systemInstruction) payload.system_instruction = systemInstruction;

  try {
    const upstream = await fetch(
      `${GEMINI_BASE}/${model}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(28_000),
      }
    );

    const data = await upstream.json();

    if (!upstream.ok) {
      return res.status(upstream.status).json({
        error: data?.error?.message || `Gemini error ${upstream.status}`,
      });
    }

    const candidates = data?.candidates;
    if (!candidates || candidates.length === 0) {
      return res.status(200).json({
        text: '',
        blockReason: data?.promptFeedback?.blockReason || null,
      });
    }

    const text = candidates[0]?.content?.parts?.[0]?.text?.trim() ?? '';
    return res.status(200).json({ text });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
});

// ── POST /api/ai/gemini/vision ───────────────────────────────────────────────
// Body: { model?, imageBase64, mimeType?, prompt, generationConfig? }
// Returns: { text, blockReason } | { error }
router.post('/gemini/vision', async (req, res) => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'Gemini API not configured on server' });

  const {
    model = 'gemini-2.5-flash',
    imageBase64,
    mimeType = 'image/jpeg',
    prompt,
    generationConfig = { temperature: 0.2, maxOutputTokens: 1024 },
  } = req.body;

  if (!imageBase64 || !prompt) {
    return res.status(400).json({ error: '`imageBase64` and `prompt` are required' });
  }

  const payload = {
    contents: [{
      parts: [
        { text: prompt },
        { inline_data: { mime_type: mimeType, data: imageBase64 } },
      ],
    }],
    generationConfig,
  };

  try {
    const upstream = await fetch(
      `${GEMINI_BASE}/${model}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(44_000),
      }
    );

    const data = await upstream.json();

    if (!upstream.ok) {
      return res.status(upstream.status).json({
        error: data?.error?.message || `Gemini error ${upstream.status}`,
      });
    }

    const candidates = data?.candidates;
    if (!candidates || candidates.length === 0) {
      return res.status(200).json({
        text: '',
        blockReason: data?.promptFeedback?.blockReason || null,
      });
    }

    const text = candidates[0]?.content?.parts?.[0]?.text?.trim() ?? '';
    return res.status(200).json({ text, blockReason: null });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
});

// ── POST /api/ai/huggingface/disease ─────────────────────────────────────────
// Body: { imageBase64 }
// Returns: [{ label, score }] | { error }
router.post('/huggingface/disease', async (req, res) => {
  const apiKey = process.env.HUGGINGFACE_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'HuggingFace API not configured on server' });

  const { imageBase64 } = req.body;
  if (!imageBase64) return res.status(400).json({ error: '`imageBase64` is required' });

  const imageBytes = Buffer.from(imageBase64, 'base64');
  const url = `https://api-inference.huggingface.co/models/${HF_DISEASE_MODEL}`;
  const headers = {
    Authorization: `Bearer ${apiKey}`,
    'Content-Type': 'application/octet-stream',
    'X-Wait-For-Model': 'true',
  };

  const attempt = () =>
    fetch(url, {
      method: 'POST',
      headers,
      body: imageBytes,
      signal: AbortSignal.timeout(55_000),
    });

  try {
    let upstream = await attempt();

    // HuggingFace returns 503 while the model cold-starts; retry once after delay
    if (upstream.status === 503) {
      await new Promise((r) => setTimeout(r, 20_000));
      upstream = await attempt();
    }

    const data = await upstream.json();

    if (!upstream.ok) {
      return res.status(upstream.status).json({
        error: data?.error || `HuggingFace error ${upstream.status}`,
      });
    }

    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
});

module.exports = router;
