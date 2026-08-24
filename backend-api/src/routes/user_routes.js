const express = require("express");
const router = express.Router();

const userController = require(
  "../controllers/user_controller"
);

// ============================================================================
// AUTHENTICATION
// ============================================================================

// Register
router.post(
  "/register",
  userController.registerUser
);

// Login
router.post(
  "/login",
  userController.loginUser
);

// Google authentication
router.post(
  "/google-login",
  userController.googleLogin
);

module.exports = router;