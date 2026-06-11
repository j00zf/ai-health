// routes/profileRoutes.js

const express = require("express");
const router = express.Router();

const auth = require("../middleware/userAuth");

// Profile controller
const {
  createProfile,
  getUserProfile,
  updateProfile,
} = require("../controllers/userProfileController");

// Dashboard controller (NEW FILE)
const {
  getDashboard,
} = require("../controllers/dashboardController");

router.post("/create", auth, createProfile);

router.get("/me", auth, getUserProfile);

router.put("/update", auth, updateProfile);

// Dashboard route (now cleanly separated)
router.get("/dashboard", auth, getDashboard);

module.exports = router;