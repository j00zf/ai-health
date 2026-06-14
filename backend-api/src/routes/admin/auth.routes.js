const express = require("express");

const router = express.Router();

const {
  registerAdmin,
  loginAdmin
} = require("../../controllers/admin/auth.controller");

const authMiddleware =
  require("../../middleware/auth.middleware");

router.post(
  "/register",
  registerAdmin
);

router.post(
  "/login",
  loginAdmin
);

router.get(
  "/dashboard",
  authMiddleware,
  (req, res) => {
    res.json({
      success: true,
      admin: req.admin
    });
  }
);

module.exports = router;