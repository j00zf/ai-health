require("dotenv").config();

process.on("uncaughtException", (err) => {
  console.error("UNCAUGHT EXCEPTION:");
  console.error(err);
});

process.on("unhandledRejection", (err) => {
  console.error("UNHANDLED REJECTION:");
  console.error(err);
});

const express = require("express");
const cors = require("cors");
const connectDB = require("./config/db");

const app = express();

const authRoutes = require("./routes/admin/auth.routes");
const adminUserRoutes = require("./routes/admin/user.routes");
const adminDashboardRoutes = require("./routes/admin/dashboard.routes");
const adminRoutes = require("./routes/admin/admin.routes");
const adminHealthRoutes = require("./routes/admin/health.routes");
const healthConnectRoutes = require("./routes/healthConnectRoutes");
const userRoutes = require("./routes/user_routes");
const healthRoutes = require("./routes/health_routes");
const profileRoutes = require("./routes/profileRoutes");
const dashboardRoutes = require("./routes/dashboard_routes");
const deviceRoutes = require("./routes/deviceRoutes");
const aiRoutes = require("./routes/aiRoutes");
const cvRoutes = require("./routes/cvRoutes");
const mlHealthRoutes = require("./routes/mlHealthRoutes");

connectDB();

app.use(cors());
app.use(express.json({ limit: "2mb" }));

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Fitbit Health API Running",
    cvPythonService: process.env.PY_CV_URL || "http://127.0.0.1:8000",
  });
});

app.use("/api/auth", authRoutes);
app.use("/api/users", adminUserRoutes);
app.use("/api/admin/health", adminHealthRoutes);
app.use("/api/admin/dashboard", adminDashboardRoutes);
app.use("/api/admins", adminRoutes);
app.use("/api/user", userRoutes);
app.use("/api/health-connect", healthConnectRoutes);
app.use("/api/health", healthRoutes);
app.use("/api/profile", profileRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/device", deviceRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/cv", cvRoutes);
app.use("/api/v1/ml-health", mlHealthRoutes);

const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
  console.log("================================");
  console.log(`Server Running On ${PORT}`);
  console.log(`Python CV: ${process.env.PY_CV_URL || "http://127.0.0.1:8000"}`);
  console.log("================================");
});
