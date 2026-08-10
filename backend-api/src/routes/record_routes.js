const express = require("express");
const router = express.Router();
const protect = require("../middleware/userAuth");

const {
  syncHealthRecord,
  getAllHealthRecords,
  getHealthRecordByDate,
  deleteHealthRecord,
} = require("../controllers/record_controller");

router.post("/sync", protect, syncHealthRecord);
router.get("/", protect, getAllHealthRecords);               // ?limit=30&page=1
router.get("/:date", protect, getHealthRecordByDate);        // /latest or /2025-08-09
router.delete("/:id", protect, deleteHealthRecord);

module.exports = router;