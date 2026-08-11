const express = require("express");
const mongoose = require("mongoose");

const router = express.Router();

router.get("/db", async (req, res) => {
  try {
    const state = mongoose.connection.readyState;

    const states = {
      0: "Disconnected",
      1: "Connected",
      2: "Connecting",
      3: "Disconnecting"
    };

    res.status(200).json({
      success: true,
      mongodb: states[state],
      database: mongoose.connection.name,
      host: mongoose.connection.host
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;