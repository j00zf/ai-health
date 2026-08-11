const express = require("express");
const router = express.Router();

const protect = require("../middleware/userAuth");

const {
  syncHealth,
  getLatestHealth,
  getHealthHistory,
  getAllHealthRecords,
  getHealthRecordByDate,
  deleteHealthRecord,
} = require("../controllers/healthConnectController");

// Sync (upsert) today's health data
router.post("/sync", protect, syncHealth);

// NOTE: fixed/reserved paths must be declared before the dynamic
// "/:date" route below, or Express will try to match them as a date.
router.get("/latest", protect, getLatestHealth);
router.get("/history", protect, getHealthHistory); // ?limit=30 (default), capped at 365
router.get("/all", protect, getAllHealthRecords); // ?limit=90&page=1 — full all-time history

// Single record lookup by date, e.g. /2026-08-09, or /latest
router.get("/:date", protect, getHealthRecordByDate);

// Delete a record by its Mongo _id
router.delete("/:id", protect, deleteHealthRecord);

module.exports = router;