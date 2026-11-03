require("dotenv").config();

const express = require("express");
const cors = require("cors");
const rateLimit = require("express-rate-limit");

const connectDB = require("./config/db");
const uploadRoutes = require("./routes/uploadRoutes");
const authRoutes = require("./routes/authRoutes");
const aiRoutes = require("./routes/aiRoutes");
const profileRoutes = require("./routes/profileRoutes");
const premiumRoutes = require("./routes/premiumRoutes");
const razorpayRoutes = require("./routes/razorpayRoutes");
const rentRoutes = require("./routes/rentRoutes");
const plantVendorRoutes = require("./routes/plantVendorRoutes");
const otpRoutes = require("./routes/otpRoutes");
const { verifyToken } = require("./middleware/auth");

const app = express();

// Render (and all cloud platforms) sit behind a reverse proxy that injects
// X-Forwarded-For.  Without this setting express-rate-limit throws
// ERR_ERL_UNEXPECTED_X_FORWARDED_FOR and cannot identify real client IPs.
app.set("trust proxy", 1);

// Rate limiters
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests. Please try again later." },
});

const uploadLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Upload rate limit exceeded. Please slow down." },
});

const aiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "AI request rate limit exceeded. Please slow down." },
});

const otpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 15,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many OTP requests. Please try again later." },
});

connectDB();

// Validate required environment variables at startup.
if (!process.env.OTPDEV_API_KEY) {
  console.warn(
    "[CONFIG] Missing environment variable: OTPDEV_API_KEY. " +
    "OTP registration endpoints will fail until this is set in Render."
  );
}

const missingRazorpay = ["RAZORPAY_KEY_ID", "RAZORPAY_KEY_SECRET", "RAZORPAY_WEBHOOK_SECRET"].filter(
  (v) => !process.env[v]
);
if (missingRazorpay.length > 0) {
  console.warn(
    `[CONFIG] Missing Razorpay environment variable(s): ${missingRazorpay.join(", ")}. ` +
    "Payment endpoints will return HTTP 500 until these are set in Render."
  );
}

// CORS
// These are the canonical Firebase Hosting origins for this project. They are
// always allowed regardless of the ALLOWED_ORIGINS env var so that a missing
// or misconfigured env var on Render does not silently break Flutter Web
// payments (which manifest as "ClientLoad failed" / XHR status 0 in the app).
const KNOWN_FIREBASE_ORIGINS = [
  "https://krishimithra-650c2.web.app",
  "https://krishimithra-650c2.firebaseapp.com",
];

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
      if (!origin) return callback(null, true);
      if (/^https?:\/\/localhost(:\d+)?$/.test(origin)) return callback(null, true);
      if (KNOWN_FIREBASE_ORIGINS.includes(origin)) return callback(null, true);
      if (allowedOrigins.length === 0) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      console.error(
        `[CORS BLOCKED] origin="${origin}" | ALLOWED_ORIGINS="${process.env.ALLOWED_ORIGINS || "(not set)"}"`
      );
      callback(new Error(`CORS: origin ${origin} not allowed`));
    },
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// Capture raw body for Razorpay webhook signature verification.
// The rawBody Buffer is stored on req and used only by the webhook handler.
app.use(
  express.json({
    limit: "15mb",
    verify: (req, _res, buf) => {
      req.rawBody = buf;
    },
  })
);

// Public health check
app.get("/", (req, res) => res.send("KM Backend Running"));

// Diagnostic endpoint — returns config status without exposing secrets.
// Used by Flutter Web to verify CORS + backend reachability before payment.
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    razorpayConfigured: !!(process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET),
    webhookConfigured: !!process.env.RAZORPAY_WEBHOOK_SECRET,
    allowedOriginsConfigured: allowedOrigins.length > 0,
  });
});

// Auth routes
app.use("/api/auth", authLimiter, authRoutes);

// AI proxy routes
app.use("/api/ai", aiLimiter, aiRoutes);

// Profile routes
app.use("/api/profile", profileRoutes);

// Premium feature entitlements and history (PayU-era routes removed; entitlements/history kept)
app.use("/api/premium", premiumRoutes);

// Razorpay payment routes — premium orders, marketplace orders, webhook
app.use("/api/razorpay", razorpayRoutes);

// RentHub machine listing
app.use("/api/rent", rentRoutes);

// Plant Vendor listing
app.use("/api/plant-vendor", plantVendorRoutes);

// OTP.dev phone verification
app.use("/api/otp", otpLimiter, otpRoutes);

// Upload route
app.use("/api", uploadLimiter, verifyToken, uploadRoutes);

const PORT = process.env.PORT || 10000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
