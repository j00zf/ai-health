const express =
  require("express");

const router =
  express.Router();

const {
  registerUser,
  loginUser,
  getProfile,
} = require(
  "../controllers/user.controller"
);

const userAuth =
  require(
    "../middleware/userAuth"
  );

router.post(
  "/register",
  registerUser
);

router.post(
  "/login",
  loginUser
);

router.get(
  "/profile",
  userAuth,
  getProfile
);

module.exports = router;