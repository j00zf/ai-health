const User = require("../models/User");
const UserProfile = require("../models/UserProfile");
const HealthRecord = require("../models/HealthRecord");
const MLHealthAnalysis = require("../models/mlHealthAnalysis");
const CVAnalysis = require("../models/CVAnalysis");

exports.getDashboard = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select("-password");

    const profile = await UserProfile.findOne({
      userId: req.user.id,
    });

    const latestRecord = await HealthRecord.findOne({
      userId: req.user.id,
    }).sort({ date: -1 });

    const latestWellness = await MLHealthAnalysis.findOne({
      user: req.user.id,
    }).sort({ analyzedAt: -1 });

    const latestStress = await CVAnalysis.findOne({
      userId: req.user.id,
    }).sort({ capturedAt: -1 });

    let wellnessScore = null;
    let wellnessStatus = "unavailable";
    if (latestWellness && latestWellness.scores && latestWellness.scores.health) {
        // Assuming scores.health is a probability [0, 1] mapped to [0, 100]
        wellnessScore = Math.round(latestWellness.scores.health * 100);
        wellnessStatus = "available";
    }

    let stressScore = null;
    let stressStatus = "unavailable";
    if (latestStress && (latestStress.stressAnalysis?.stressScore !== undefined || latestStress.derivedSignals?.stressScore !== undefined)) {
        const rawStress = latestStress.stressAnalysis?.stressScore ?? latestStress.derivedSignals?.stressScore;
        if (rawStress !== null && rawStress !== undefined) {
             stressScore = Math.round(rawStress * 100);
             stressStatus = "available";
        }
    }

    res.status(200).json({
      success: true,
      message: "Dashboard loaded successfully",

      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          photoUrl: user.photoUrl,
          profileCompleted: user.profileCompleted,
        },

        profile: profile,
        
        scores: {
          wellnessScore: wellnessScore,
          wellnessStatus: wellnessStatus,
          stressScore: stressScore,
          stressStatus: stressStatus,
        },

        stats: {
          steps: latestRecord?.steps ?? 0,
          calories: latestRecord?.calories ?? 0,
          sleep: latestRecord?.sleepHours ?? 0,
          heartRate: latestRecord?.heartRate ?? 0,
          restingHeartRate: latestRecord?.restingHeartRate ?? 0,
          distanceWalked: latestRecord?.distanceWalked ?? 0,
          activeHours: latestRecord?.activeHours ?? 0,
          floors: latestRecord?.floors ?? 0,
          activeZoneMinutes: latestRecord?.activeZoneMinutes ?? 0,
          bloodOxygen: latestRecord?.bloodOxygen ?? 0,
          bodyTemperature: latestRecord?.bodyTemperature ?? 0,
          weight: latestRecord?.weight ?? 0,
        },

        // Matches the key the Flutter DashboardScreen reads:
        // devices["healthConnected"]
        devices: {
          healthConnected: profile?.healthConnected ?? false,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};