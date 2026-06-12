// routes/deviceRoutes.js
const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const deviceController = require("../controllers/deviceController");

router.post("/fitbit/connect", protect, deviceController.connectFitbit);
router.get("/my-devices", protect, deviceController.getDevices);

module.exports = router;