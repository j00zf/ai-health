const express = require("express");
const router = express.Router();
const protect = require("../middleware/userAuth");

const {
  syncHealth,
  syncHealthBulk,
  getLatestHealth,
  getHealthHistory,
  getAllHealthRecords,
  getHealthAverages,
  getHealthRecordByDate,
  deleteHealthRecord,
  getHealthSnapshot,
  updateHealthSyncPoints,
  syncHealthIncremental,
} = require("../controllers/healthConnectController");

router.post("/sync", protect, syncHealth);
router.post("/sync-bulk", protect, syncHealthBulk);
router.get("/snapshot", protect, getHealthSnapshot);
router.post("/sync-points", protect, updateHealthSyncPoints);
router.post("/sync-incremental", protect, syncHealthIncremental);

router.get("/latest", protect, getLatestHealth);
router.get("/history", protect, getHealthHistory);
router.get("/all", protect, getAllHealthRecords);
router.get("/averages", protect, getHealthAverages);

router.get("/:date", protect, getHealthRecordByDate);
router.delete("/:id", protect, deleteHealthRecord);

module.exports = router;
