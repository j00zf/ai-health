const express = require("express");
const router = express.Router();

const {
  getAllUsers,
  getUserHealthRecords,
} = require("../../controllers/admin/user.controller");

router.get("/all", getAllUsers);
router.get("/:userId/records", getUserHealthRecords);

module.exports = router;