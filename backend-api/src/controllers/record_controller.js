const HealthRecord = require("../models/record_HealthRecord");
const UserProfile = require("../models/UserProfile");

// ================================
// Sync / Upsert today’s health data
// ================================
exports.syncHealthRecord = async (req, res) => {
  try {
    const {
      steps,
      heartRate,
      restingHeartRate,
      calories,
      sleepHours,
      bloodOxygen,
      bodyTemperature,
      distanceWalked,
      activeHours,
      source,
      syncedAt,
    } = req.body;

    const today = new Date().toISOString().split("T")[0];

    const record = await HealthRecord.findOneAndUpdate(
      { userId: req.user.id, date: today },
      {
        userId: req.user.id,
        date: today,
        steps: Number(steps ?? 0),
        distanceWalked: Number(distanceWalked ?? 0),
        calories: Number(calories ?? 0),
        activeHours: Number(activeHours ?? 0),
        heartRate: Number(heartRate ?? 0),
        restingHeartRate: Number(restingHeartRate ?? 0),
        sleepHours: Number(sleepHours ?? 0),
        bloodOxygen: Number(bloodOxygen ?? 0),
        bodyTemperature: Number(bodyTemperature ?? 0),
        source: source ?? "Unknown",
        syncedAt: syncedAt ? new Date(syncedAt) : new Date(),
      },
      { upsert: true, new: true, runValidators: true }
    );

    // Mark Health Connect as linked
    await UserProfile.findOneAndUpdate(
      { userId: req.user.id },
      { healthConnected: true },
      { upsert: true }
    );

    res.status(200).json({
      success: true,
      message: "Health data synced successfully",
      record,
    });
  } catch (error) {
    console.error("Health Sync Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ================================
// Get ALL records for the signed-in user
// ================================
exports.getAllHealthRecords = async (req, res) => {
  try {
    const { limit = 90, page = 1 } = req.query;
    const skip = (Number(page) - 1) * Number(limit);

    const [records, total] = await Promise.all([
      HealthRecord.find({ userId: req.user.id })
        .sort({ date: -1 })
        .skip(skip)
        .limit(Number(limit)),
      HealthRecord.countDocuments({ userId: req.user.id }),
    ]);

    res.status(200).json({
      success: true,
      count: records.length,
      total,
      page: Number(page),
      pages: Math.ceil(total / Number(limit)),
      data: records,
    });
  } catch (error) {
    console.error("Fetch All Health Records Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ================================
// Get single record by date (or latest)
// ================================
exports.getHealthRecordByDate = async (req, res) => {
  try {
    const { date } = req.params; // YYYY-MM-DD or "latest"

    let record;
    if (date === "latest") {
      record = await HealthRecord.findOne({ userId: req.user.id }).sort({
        syncedAt: -1,
      });
    } else {
      record = await HealthRecord.findOne({
        userId: req.user.id,
        date,
      });
    }

    if (!record) {
      return res.status(404).json({
        success: false,
        message: "No health record found for this date",
      });
    }

    res.status(200).json({ success: true, data: record });
  } catch (error) {
    console.error("Fetch Health Record Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ================================
// Delete a record (optional)
// ================================
exports.deleteHealthRecord = async (req, res) => {
  try {
    const { id } = req.params;

    const record = await HealthRecord.findOneAndDelete({
      _id: id,
      userId: req.user.id, // security: only own records
    });

    if (!record) {
      return res.status(404).json({
        success: false,
        message: "Record not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Health record deleted",
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};