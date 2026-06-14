const express = require("express");
const router = express.Router();

// Protect route middleware
const protect = require("../middleware/userAuth"); 

// Import both controllers separately
const deviceController = require("../controllers/deviceController");

// --- Routes mapping to deviceController.js ---
router.post("/fitbit/connect", protect, deviceController.connectFitbit);
router.get("/my-devices", protect, deviceController.getDevices);


module.exports = router;