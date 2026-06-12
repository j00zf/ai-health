// models/DeviceConnection.js
const mongoose = require("mongoose");

const deviceConnectionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  deviceType: {
    type: String,
    enum: ["fitbit", "apple_watch", "google_fit"],
    required: true,
  },
  connected: {
    type: Boolean,
    default: false,
  },
  accessToken: {
    type: String,
    required: true,
  },
  refreshToken: {
    type: String,
  },
  expiresAt: {
    type: Date,
  },
  fitbitUserId: String,        // Fitbit's user ID
  lastSyncedAt: {
    type: Date,
    default: null,
  },
}, {
  timestamps: true,
});

// Index for quick lookup
deviceConnectionSchema.index({ userId: 1, deviceType: 1 }, { unique: true });

module.exports = mongoose.model("DeviceConnection", deviceConnectionSchema);