require("dotenv").config();

const express = require("express");
const cors = require("cors");
const rateLimit = require("express-rate-limit");

const connectDB = require("./config/db");
const uploadRoutes = require("./routes/uploadRoutes");
const authRoutes = require("./routes/authRoutes");
const aiRoutes = require("./routes/aiRoutes");
const profileRoutes = require("./routes/profileRoutes");
const paymentRoutes = require("./routes/paymentRoutes");
const premiumRoutes = require("./routes/premiumRoutes");
const rentRoutes = require("./routes/rentRoutes");
const { verifyToken } = require("./middleware/auth");

const app = express();

// Render (and all cloud platforms) sit behind a reverse proxy that injects
// X-Forwarded-For.  Without this setting express-rate-limit throws
// ERR_ERL_UNEXPECTED_X_FORWARDED_FOR and cannot identify real client IPs.
// '1' means trust exactly one proxy hop (Render's load balancer).
app.set("trust proxy", 1);

// Rate limiters — keyed by client IP.
// Auth routes: tight limit to block brute-force attacks.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests. Please try again later." },
});

// Upload routes: prevent abuse of the Cloudinary pipeline.
const uploadLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Upload rate limit exceeded. Please slow down." },
});

// AI routes: chatbot/crop-detection — generous but bounded.
const aiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "AI request rate limit exceeded. Please slow down." },
});

connectDB();

// Validate required PayU environment variables at startup.
// The app still starts and serves non-payment endpoints without these,
// but any payment endpoint call will fail with HTTP 500.
// Set PAYU_KEY, PAYU_SALT (and optionally PAYU_ENV) in your Render
// environment variables dashboard before accepting payments.
const missingPayU = ["PAYU_KEY", "PAYU_SALT"].filter((v) => !process.env[v]);
if (missingPayU.length > 0) {
  console.warn(
    `[CONFIG] Missing environment variable(s): ${missingPayU.join(", ")}. ` +
    "Payment endpoints will return HTTP 500 until these are set in Render."
  );
}

// CORS: native mobile sends no Origin header — always allow.
// For web clients, only allow origins listed in ALLOWED_ORIGINS (comma-separated).
// When ALLOWED_ORIGINS is unset, all web origins are allowed (development mode).
const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

if (allowedOrigins.length === 0 && process.env.NODE_ENV === "production") {
  console.warn(
    "[SECURITY WARNING] ALLOWED_ORIGINS is not set. " +
    "All web origins are allowed. Set ALLOWED_ORIGINS in your environment."
  );
}

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true); // mobile / server-to-server
      // Always allow localhost so Flutter Web works during local development,
      // regardless of what ALLOWED_ORIGINS is set to in production.
      if (/^https?:\/\/localhost(:\d+)?$/.test(origin)) return callback(null, true);
      if (allowedOrigins.length === 0) return callback(null, true); // dev mode
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error(`CORS: origin ${origin} not allowed`));
    },
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// Increased limit covers base64-encoded images sent to AI proxy routes (~15 MB max)
app.use(express.json({ limit: "15mb" }));

// Public health check
app.get("/", (req, res) => res.send("KM Backend Running"));

// Auth routes (Firebase token → find/create MongoDB user)
app.use("/api/auth", authLimiter, authRoutes);

// AI proxy routes — keys are server-side; no client auth required
// Must be registered before /api to avoid hitting the verifyToken middleware
app.use("/api/ai", aiLimiter, aiRoutes);

// Profile routes — GET /photo/:id is public; POST /photo applies verifyToken internally.
// Must be registered before the catch-all /api route below.
app.use("/api/profile", profileRoutes);

// Payment routes — create, dynamic hash generation, verify, cancel, webhook
app.use("/api/payment", paymentRoutes);

// Premium feature payment routes — entitlements, purchase, verify, webhook
app.use("/api/premium", premiumRoutes);

// RentHub machine listing (publish) — owner-only, requires entitlement check
app.use("/api/rent", rentRoutes);

// Upload route — requires valid Firebase ID token
app.use("/api", uploadLimiter, verifyToken, uploadRoutes);

const PORT = process.env.PORT || 10000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
