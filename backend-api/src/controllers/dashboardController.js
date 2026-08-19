const User = require("../models/User");
const UserProfile = require("../models/UserProfile");
const HealthRecord = require("../models/HealthRecord");

exports.getDashboard = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select("-password");

    const profile = await UserProfile.findOne({
      userId: req.user.id,
    });

    const latestRecord = await HealthRecord.findOne({
      userId: req.user.id,
    }).sort({ date: -1 });

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