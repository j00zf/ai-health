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