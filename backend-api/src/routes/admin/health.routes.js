const express = require("express");
const router = express.Router();
const { getAllHealthRecords } = require("../../controllers/admin/health.controller");

// Route path: GET /api/admin/health/all
router.get("/all", getAllHealthRecords);

module.exports = router;