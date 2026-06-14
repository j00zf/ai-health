const express = require("express");
const router = express.Router();

const protect =
  require("../middleware/userAuth");

const {
  syncHealth,
  getLatestHealth,
  getHealthHistory,
} = require(
  "../controllers/healthConnectController"
);

router.post(
  "/sync",
  protect,
  syncHealth
);

router.get(
  "/latest",
  protect,
  getLatestHealth
);

router.get(
  "/history",
  protect,
  getHealthHistory
);

module.exports = router;