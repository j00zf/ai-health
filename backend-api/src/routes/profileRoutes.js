const express = require("express");
const router = express.Router();

const auth = require("../middleware/userAuth");

const {
  createProfile,
  getUserProfile,
  updateProfile,
} = require("../controllers/userProfileController");

const {
  getDashboard,
} = require("../controllers/dashboardController");

// ============================================================================
// USER PROFILE
// ============================================================================

// Create profile
router.post(
  "/create",
  auth,
  createProfile
);

// Get currently authenticated user's profile
router.get(
  "/me",
  auth,
  getUserProfile
);

// Update currently authenticated user's profile
router.put(
  "/update",
  auth,
  updateProfile
);

// ============================================================================
// USER DASHBOARD
// ============================================================================

router.get(
  "/dashboard",
  auth,
  getDashboard
);

module.exports = router;