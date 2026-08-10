const mongoose = require("mongoose");

const healthRecordSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    date: {
      type: String, // YYYY-MM-DD
      required: true,
      index: true,
    },

    // Activity
    steps: { type: Number, default: 0 },
    distanceWalked: { type: Number, default: 0 }, // km
    calories: { type: Number, default: 0 },
    activeHours: { type: Number, default: 0 },

    // Heart
    heartRate: { type: Number, default: 0 },
    restingHeartRate: { type: Number, default: 0 },

    // Sleep
    sleepHours: { type: Number, default: 0 },

    // Advanced
    bloodOxygen: { type: Number, default: 0 },
    bodyTemperature: { type: Number, default: 0 },

    // Meta
    source: { type: String, default: "Unknown" },
    syncedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

// One record per user per day
healthRecordSchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model("HealthRecord", healthRecordSchema);