const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const rateLimit = require('express-rate-limit');

dotenv.config();

const app = express();

// ── CORS — must be registered BEFORE all routes ───────────────────────────────
//
// origin: true  → mirrors the incoming Origin header back, allowing any origin.
// This is required for Flutter Web (browser) to accept responses.
// preflightContinue: false  → cors handles OPTIONS internally, no next() needed.
// optionsSuccessStatus: 200 → some older browsers need 200 (not 204) for OPTIONS.
//
// NOTE: Do NOT use app.options('*', ...) — Express 5 / path-to-regexp throws
//       PathError on wildcard '*'. The cors middleware handles preflight correctly.

app.use(
  cors({
    origin: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    credentials: false,
    preflightContinue: false,
    optionsSuccessStatus: 200,
  })
);

// ── Body parsers ──────────────────────────────────────────────────────────────

app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// ── Rate limiting ─────────────────────────────────────────────────────────────

const chatLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'Too many requests. Please wait a moment and try again.',
  },
});

// ── Health check ──────────────────────────────────────────────────────────────

app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'KrishiMithra Chatbot Backend is running',
    model: process.env.GROQ_MODEL || 'llama-3.3-70b-versatile (default)',
  });
});

// ── Chat route ────────────────────────────────────────────────────────────────

const chatRouter = require('./routes/chat');
app.use('/api/chat', chatLimiter, chatRouter);

// ── 404 ───────────────────────────────────────────────────────────────────────

app.use((req, res) => {
  res.status(404).json({ success: false, error: 'Route not found', path: req.originalUrl });
});

// ── Global error handler ──────────────────────────────────────────────────────

app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err.message || err);
  res.status(500).json({ success: false, error: 'Internal server error' });
});

// ── Start ─────────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log('==============================================');
  console.log('🌱  KrishiMithra Chatbot Backend');
  console.log('==============================================');
  console.log(`🚀  Port    : ${PORT}`);
  console.log(`🤖  Model   : ${process.env.GROQ_MODEL || 'llama-3.3-70b-versatile (default)'}`);
  console.log(`❤️   Health  : http://localhost:${PORT}/health`);
  console.log(`💬  Chat    : http://localhost:${PORT}/api/chat`);
  console.log('==============================================');
});
