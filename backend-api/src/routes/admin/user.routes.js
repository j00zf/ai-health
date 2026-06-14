const express = require("express");

const router =
  express.Router();

const {
  getAllUsers,
} = require(
  "../../controllers/admin/user.controller"
);

router.get(
  "/all",
  getAllUsers
);

module.exports = router;