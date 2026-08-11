const HealthRecord = require("../models/HealthRecord");
const UserProfile = require("../models/UserProfile");

// ================================
// Sync / Upsert today's health data
// ================================
exports.syncHealth = async (req, res) => {
  try {
    const {
      steps,
      distanceWalked,
      calories,
      activeHours,
      floors,
      activeZoneMinutes,
      heartRate,
      restingHeartRate,
      sleepHours,
      bloodOxygen,
      bodyTemperature,
      weight,
      source,
      syncedAt,
    } = req.body;

    const today = new Date().toISOString().split("T")[0];

    const record = await HealthRecord.findOneAndUpdate(
      {
        userId: req.user.id,
        date: today,
      },
      {
        userId: req.user.id,
        date: today,

        // Activity
        steps: Number(steps ?? 0),
        distanceWalked: Number(distanceWalked ?? 0),
        calories: Number(calories ?? 0),
        activeHours: Number(activeHours ?? 0),
        floors: Number(floors ?? 0),
        activeZoneMinutes: Number(activeZoneMinutes ?? 0),

        // Heart
        heartRate: Number(heartRate ?? 0),
        restingHeartRate: Number(restingHeartRate ?? 0),

        // Sleep
        sleepHours: Number(sleepHours ?? 0),

        // Advanced
        bloodOxygen: Number(bloodOxygen ?? 0),
        bodyTemperature: Number(bodyTemperature ?? 0),
        weight: Number(weight ?? 0),

        // Meta
        source: source ?? "Unknown",
        syncedAt: syncedAt ? new Date(syncedAt) : new Date(),
      },
      {
        upsert: true,
        new: true,
        runValidators: true,
      }
    );

    // Mark Health Connect as linked on the user's profile
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

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ================================
// Get Latest Health Record
// ================================
exports.getLatestHealth = async (req, res) => {
  try {
    const latestRecord = await HealthRecord.findOne({
      userId: req.user.id,
    }).sort({ date: -1 });

    if (!latestRecord) {
      return res.status(404).json({
        success: false,
        message: "No health records found",
      });
    }

    res.status(200).json({
      success: true,
      data: latestRecord,
    });
  } catch (error) {
    console.error("Fetch Latest Health Error:", error);

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ================================
// Get recent Health History (bounded — default last 30 days)
// Use /all below for the full, paginated, all-time history.
// ================================
exports.getHealthHistory = async (req, res) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 30, 365);

    const records = await HealthRecord.find({ userId: req.user.id })
      .sort({ date: -1 })
      .limit(limit);

    res.status(200).json({
      success: true,
      count: records.length,
      data: records,
    });
  } catch (error) {
    console.error("Fetch Health History Error:", error);

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ================================
// Get ALL records for the signed-in user — full, paginated, all-time history
// GET /api/health-connect/all?limit=90&page=1
// ================================
exports.getAllHealthRecords = async (req, res) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 90, 365);
    const page = Math.max(Number(req.query.page) || 1, 1);
    const skip = (page - 1) * limit;

    const [records, total] = await Promise.all([
      HealthRecord.find({ userId: req.user.id })
        .sort({ date: -1 })
        .skip(skip)
        .limit(limit),
      HealthRecord.countDocuments({ userId: req.user.id }),
    ]);

    res.status(200).json({
      success: true,
      count: records.length,
      total,
      page,
      pages: Math.max(Math.ceil(total / limit), 1),
      data: records,
    });
  } catch (error) {
    console.error("Fetch All Health Records Error:", error);

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ================================
// Get a single record by date ("YYYY-MM-DD" or "latest")
// GET /api/health-connect/2026-08-09
// ================================
exports.getHealthRecordByDate = async (req, res) => {
  try {
    const { date } = req.params;

    let record;

    if (date === "latest") {
      record = await HealthRecord.findOne({ userId: req.user.id }).sort({
        date: -1,
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

    res.status(200).json({
      success: true,
      data: record,
    });
  } catch (error) {
    console.error("Fetch Health Record Error:", error);

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ================================
// Delete a record by its Mongo _id
// ================================
exports.deleteHealthRecord = async (req, res) => {
  try {
    const { id } = req.params;

    const record = await HealthRecord.findOneAndDelete({
      _id: id,
      userId: req.user.id, // security: only allow deleting your own record
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
    console.error("Delete Health Record Error:", error);

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};