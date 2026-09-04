const express = require("express");

const router =
express.Router();

const auth =
require(
"../middleware/userAuth"
);

const {
mlAnalyzeHealth,
mlGetDashboard,
mlGetHistory,
mlGetImprovement,
mlGetLatestAnalysis,
mlGetLatestHealthRecord,
getWellnessSummaries,
} = require(
"../controllers/mlHealthController"
);

// ============================================================
// RUN ML ANALYSIS
// ============================================================

router.post(
"/analyze",
auth,
mlAnalyzeHealth
);

// ============================================================
// GET LATEST HEALTH RECORD
// ============================================================

router.get(
"/latest-record",
auth,
mlGetLatestHealthRecord
);

// ============================================================
// ML DASHBOARD
// ============================================================

router.get(
"/dashboard",
auth,
mlGetDashboard
);

// ============================================================
// LATEST ML ANALYSIS
// ============================================================

router.get(
"/latest",
auth,
mlGetLatestAnalysis
);

// ============================================================
// ML HISTORY
// ============================================================

router.get(
"/history",
auth,
mlGetHistory
);

// ============================================================
// ML IMPROVEMENT
// ============================================================

router.get(
"/improvement",
auth,
mlGetImprovement
);

// ============================================================
// WELLNESS SUMMARIES
// ============================================================

router.get(
"/summaries",
auth,
getWellnessSummaries
);

module.exports =
router;
