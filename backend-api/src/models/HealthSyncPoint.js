const mongoose = require("mongoose");

const healthSyncPointSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true, index: true },
  lastFullSyncAt: { type: Date, default: null },
  lastDailySyncAt: { type: Date, default: null },
  lastWeeklySyncAt: { type: Date, default: null },
  lastMonthlySyncAt: { type: Date, default: null },
  lastSyncAt: { type: Date, default: null },
  lastSyncRangeDays: { type: Number, default: 0 },
}, { timestamps: true });

module.exports = mongoose.models.HealthSyncPoint || mongoose.model("HealthSyncPoint", healthSyncPointSchema);
