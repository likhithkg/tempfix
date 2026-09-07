require("dotenv").config();

const express = require("express");
const cors = require("cors");

const connectDB = require("./config/db");
const uploadRoutes = require("./routes/uploadRoutes");
const authRoutes = require("./routes/authRoutes");
const { verifyToken } = require("./middleware/auth");

const app = express();

connectDB();

app.use(cors());
app.use(express.json());

// Public health check
app.get("/", (req, res) => res.send("KM Backend Running"));

// Auth routes (verify Firebase token → find/create user in MongoDB)
app.use("/api/auth", authRoutes);

// Upload route — requires valid Firebase ID token
app.use("/api", verifyToken, uploadRoutes);

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});