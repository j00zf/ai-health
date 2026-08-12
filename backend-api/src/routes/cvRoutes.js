const express = require("express");

const router = express.Router();

const protect = require("../middleware/userAuth");
const cvController = require("../controllers/cvController");

// ============================================================================
// CV ANALYSIS
// ============================================================================

// -----------------------------------------------------------------------------
// Analyze and store a new CV feature payload
// POST /api/cv/analyze
// -----------------------------------------------------------------------------

router.post(
    "/analyze",
    protect,
    cvController.analyze
);

// -----------------------------------------------------------------------------
// Get latest CV analysis
// GET /api/cv/latest
// -----------------------------------------------------------------------------

router.get(
    "/latest",
    protect,
    cvController.getLatest
);

// -----------------------------------------------------------------------------
// Get CV history
// GET /api/cv/history
// -----------------------------------------------------------------------------

router.get(
    "/history",
    protect,
    cvController.getHistory
);

// -----------------------------------------------------------------------------
// Get overall CV summary
// GET /api/cv/summary
// -----------------------------------------------------------------------------

router.get(
    "/summary",
    protect,
    cvController.getSummary
);

// -----------------------------------------------------------------------------
// Get CV trends
// GET /api/cv/trends
// -----------------------------------------------------------------------------

router.get(
    "/trends",
    protect,
    cvController.getTrends
);

// -----------------------------------------------------------------------------
// Get a single CV analysis
// GET /api/cv/:id
// -----------------------------------------------------------------------------

router.get(
    "/:id",
    protect,
    cvController.getById
);

// -----------------------------------------------------------------------------
// Delete a CV analysis
// DELETE /api/cv/:id
// -----------------------------------------------------------------------------

router.delete(
    "/:id",
    protect,
    cvController.delete
);

// ============================================================================
// EXPORT
// ============================================================================

module.exports = router;