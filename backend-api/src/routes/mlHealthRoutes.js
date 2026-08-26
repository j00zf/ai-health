const express = require("express");

const {
    analyzeMlHealth,
    getMlHealthStatus,
} = require(
    "../controllers/mlHealthController"
);


const router =
    express.Router();


// ============================================================
// PULSE AI ANALYSIS
// ============================================================

router.post(
    "/analyze",
    analyzeMlHealth
);


// ============================================================
// PULSE AI HEALTH CHECK
// ============================================================

router.get(
    "/status",
    getMlHealthStatus
);


module.exports =
    router;