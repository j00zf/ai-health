const express = require("express");
const router = express.Router();

const userController = require("../controllers/user_controller"); // ← fixed: was "user.controller"

router.post(
  "/register",
  userController.registerUser
);

router.post(
  "/login",
  userController.loginUser
);

router.post(
  "/google-login",
  userController.googleLogin
);

module.exports = router;