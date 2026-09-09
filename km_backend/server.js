require("dotenv").config();

const express = require("express");
const cors = require("cors");

const connectDB = require("./config/db");
const uploadRoutes = require("./routes/uploadRoutes");
const authRoutes = require("./routes/authRoutes");
const aiRoutes = require("./routes/aiRoutes");
const profileRoutes = require("./routes/profileRoutes");
const { verifyToken } = require("./middleware/auth");

const app = express();

connectDB();

// CORS: native mobile sends no Origin header — always allow.
// For web clients, only allow origins listed in ALLOWED_ORIGINS (comma-separated).
// When ALLOWED_ORIGINS is unset, all web origins are allowed (development mode).
const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true); // mobile / server-to-server
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
app.use("/api/auth", authRoutes);

// AI proxy routes — keys are server-side; no client auth required
// Must be registered before /api to avoid hitting the verifyToken middleware
app.use("/api/ai", aiRoutes);

// Profile routes — GET /photo/:id is public; POST /photo applies verifyToken internally.
// Must be registered before the catch-all /api route below.
app.use("/api/profile", profileRoutes);

// Upload route — requires valid Firebase ID token
app.use("/api", verifyToken, uploadRoutes);

const PORT = process.env.PORT || 10000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
