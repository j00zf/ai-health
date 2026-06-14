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
      type: String,
      required: true,
      index: true,
    },

    // Activity Metrics
    steps: {
      type: Number,
      default: 0,
    },

    distanceWalked: {
      type: Number,
      default: 0,
    },

    calories: {
      type: Number,
      default: 0,
    },

    activeHours: {
      type: Number,
      default: 0,
    },

    // Heart Metrics
    heartRate: {
      type: Number,
      default: 0,
    },

    restingHeartRate: {
      type: Number,
      default: 0,
    },

    // Sleep Metrics
    sleepHours: {
      type: Number,
      default: 0,
    },

    // Advanced Health Metrics
    bloodOxygen: {
      type: Number,
      default: 0,
    },

    bodyTemperature: {
      type: Number,
      default: 0,
    },

    // Metadata
    source: {
      type: String,
      default: "Unknown",
    },

    syncedAt: {
      type: Date,
      default: Date.now,
    },

    // AI Prediction Results
    riskScore: {
      type: Number,
      default: 0,
    },

    riskLevel: {
      type: String,
      enum: ["Low", "Moderate", "High"],
      default: "Low",
    },

    predictionMessage: {
      type: String,
      default: "",
    },
  },
  {
    timestamps: true,
  }
);

// Prevent duplicate records for same user/day
healthRecordSchema.index(
  {
    userId: 1,
    date: 1,
  },
  {
    unique: true,
  }
);

module.exports = mongoose.model(
  "HealthRecord",
  healthRecordSchema
);