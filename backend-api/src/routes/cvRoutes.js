const express = require("express");

const router = express.Router();

const protect = require("../middleware/userAuth");

const cvController = require("../controllers/cvController");

// ============================================================================
// CV ANALYSIS
// ============================================================================

// Analyze a new image / CV feature payload
router.post(
  "/analyze",
  protect,
  cvController.analyze
);

// Get latest analysis
router.get(
  "/latest",
  protect,
  cvController.getLatest
);

// Get CV history
router.get(
  "/history",
  protect,
  cvController.getHistory
);

// Get overall CV summary
router.get(
  "/summary",
  protect,
  cvController.getSummary
);

// Get CV trends
router.get(
  "/trends",
  protect,
  cvController.getTrends
);

// Get single analysis
router.get(
  "/:id",
  protect,
  cvController.getById
);

// Delete analysis
router.delete(
  "/:id",
  protect,
  cvController.delete
);

// ============================================================================
// CV SESSIONS
// ============================================================================

router.post(
  "/session/start",
  protect,
  cvController.startSession
);

router.post(
  "/session/:id/end",
  protect,
  cvController.endSession
);

router.get(
  "/session/:id",
  protect,
  cvController.getSession
);

module.exports = router;