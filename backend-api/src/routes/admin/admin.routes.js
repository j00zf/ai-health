const express = require("express");

const router =
  express.Router();

const {
  getAllAdmins,
} = require(
  "../../controllers/admin/admin.controller"
);

router.get(
  "/all",
  getAllAdmins
);

module.exports = router;