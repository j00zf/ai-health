const mongoose = require("mongoose");

const healthRecordSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // YYYY-MM-DD — one record per user per calendar day.
    date: {
      type: String,
      required: true,
      index: true,
    },

    // Activity
    steps: { type: Number, default: 0 },
    distanceWalked: { type: Number, default: 0 }, // km
    calories: { type: Number, default: 0 }, // kcal
    activeHours: { type: Number, default: 0 },
    floors: { type: Number, default: 0 },
    activeZoneMinutes: { type: Number, default: 0 },

    // Heart
    heartRate: { type: Number, default: 0 },
    restingHeartRate: { type: Number, default: 0 },

    // Sleep
    sleepHours: { type: Number, default: 0 },

    // Advanced measurements
    bloodOxygen: { type: Number, default: 0 },
    bodyTemperature: { type: Number, default: 0 }, // °C
    weight: { type: Number, default: 0 }, // kg

    // Meta
    source: { type: String, default: "Unknown" },
    recordHash: { type: String, default: "", index: true },
    syncedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

healthRecordSchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports =
  mongoose.models.HealthRecord ||
  mongoose.model("HealthRecord", healthRecordSchema);
