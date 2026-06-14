const HealthRecord = require("../models/HealthRecord");
const UserProfile = require("../models/UserProfile");

// ================================
// Sync Health Connect Data
// ================================
exports.syncHealth = async (req, res) => {
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

    const today =
      new Date()
        .toISOString()
        .split("T")[0];

    const record =
      await HealthRecord.findOneAndUpdate(
        {
          userId: req.user.id,
          date: today,
        },
        {
          userId: req.user.id,
          date: today,

          // Activity Metrics
          steps: Number(steps ?? 0),
          distanceWalked: Number(
            distanceWalked ?? 0
          ),
          calories: Number(
            calories ?? 0
          ),
          activeHours: Number(
            activeHours ?? 0
          ),

          // Heart Metrics
          heartRate: Number(
            heartRate ?? 0
          ),
          restingHeartRate: Number(
            restingHeartRate ?? 0
          ),

          // Sleep
          sleepHours: Number(
            sleepHours ?? 0
          ),

          // Advanced Metrics
          bloodOxygen: Number(
            bloodOxygen ?? 0
          ),
          bodyTemperature: Number(
            bodyTemperature ?? 0
          ),

          // Metadata
          source:
            source ?? "Unknown",

          syncedAt:
            syncedAt
              ? new Date(syncedAt)
              : new Date(),
        },
        {
          upsert: true,
          new: true,
          runValidators: true,
        }
      );

    // Mark Health Connect as linked
    await UserProfile.findOneAndUpdate(
      {
        userId: req.user.id,
      },
      {
        healthConnected: true,
      }
    );

    res.status(200).json({
      success: true,
      message:
        "Health data synced successfully",
      record,
    });
  } catch (error) {
    console.error(
      "Health Sync Error:",
      error
    );

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ================================
// Get Latest Health Record
// ================================
exports.getLatestHealth = async (
  req,
  res
) => {
  try {
    const latestRecord =
      await HealthRecord.findOne({
        userId: req.user.id,
      }).sort({
        syncedAt: -1,
      });

    if (!latestRecord) {
      return res.status(404).json({
        success: false,
        message:
          "No health records found",
      });
    }

    res.status(200).json({
      success: true,
      data: latestRecord,
    });
  } catch (error) {
    console.error(
      "Fetch Latest Health Error:",
      error
    );

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ================================
// Get Health History
// ================================
exports.getHealthHistory =
  async (req, res) => {
    try {
      const records =
        await HealthRecord.find({
          userId: req.user.id,
        })
          .sort({
            date: -1,
          })
          .limit(30);

      res.status(200).json({
        success: true,
        count: records.length,
        data: records,
      });
    } catch (error) {
      console.error(
        "Fetch Health History Error:",
        error
      );

      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  };