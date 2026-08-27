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
} = require(
    "../controllers/mlHealthController"
);


// ============================================================
// ML ANALYSIS
// ============================================================

router.post(
    "/analyze",
    auth,
    mlAnalyzeHealth
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


module.exports =
    router;