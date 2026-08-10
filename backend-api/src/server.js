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

// Create app
const app = express();

// Route imports
const authRoutes = require("./routes/admin/auth.routes");
const adminUserRoutes = require("./routes/admin/user.routes");
const adminDashboardRoutes = require("./routes/admin/dashboard.routes");
const adminRoutes = require("./routes/admin/admin.routes");
const healthConnectRoutes = require("./routes/healthConnectRoutes");
const userRoutes = require("./routes/user.routes");
const healthRoutes = require("./routes/health.routes");
const profileRoutes = require("./routes/profileRoutes");
const dashboardRoutes = require("./routes/dashboard.routes");
const deviceRoutes = require("./routes/deviceRoutes");

// Database
connectDB();

// Middleware
app.use(cors());
app.use(express.json());

// Home Route
app.get("/", (req, res) => {
    res.json({
        success: true,
        message: "Fitbit Health API Running",
    });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", adminUserRoutes);
app.use("/api/admin/dashboard", adminDashboardRoutes);
app.use("/api/admins", adminRoutes);
app.use("/api/records", require("./routes/record_routes"));
app.use("/api/user", userRoutes);
app.use("/api/health-connect", healthConnectRoutes);
app.use("/api/health", healthRoutes);
app.use("/api/profile", profileRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/device", deviceRoutes);

// Server
const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
    console.log("================================");
    console.log(`Server Running On ${PORT}`);
    console.log("================================");
});