const express = require("express");
const router = express.Router();

// Protect route middleware
const protect = require("../middleware/userAuth"); 

// Import both controllers separately
const deviceController = require("../controllers/deviceController");

// --- Routes mapping to deviceController.js ---
router.post("/fitbit/connect", protect, deviceController.connectFitbit);
router.get("/my-devices", protect, deviceController.getDevices);

// --- Routes mapping to fitbitController.js ---
router.post("/fitbit/sync", protect, fitbitController.syncDailyData);
router.get("/fitbit/data", protect, fitbitController.getFitbitData);

module.exports = router;