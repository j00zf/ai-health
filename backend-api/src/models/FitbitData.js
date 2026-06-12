const mongoose = require("mongoose");

const fitbitDataSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  date: {
    type: String, // YYYY-MM-DD
    required: true,
  },

  // Steps
  steps: {
    type: Number,
    default: 0,
  },

  // Heart Rate
  heartRate: {
    resting: { type: Number, default: null },
    min: { type: Number, default: null },
    max: { type: Number, default: null },
  },

  // Sleep
  sleep: {
    duration: { type: Number, default: 0 }, // in minutes
    efficiency: { type: Number, default: null },
    deep: { type: Number, default: null },
    light: { type: Number, default: null },
    rem: { type: Number, default: null },
    awake: { type: Number, default: null },
  },

  caloriesOut: {
    type: Number,
    default: 0,
  },

  syncedAt: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
});

// Unique index per user per day
fitbitDataSchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model("FitbitData", fitbitDataSchema);