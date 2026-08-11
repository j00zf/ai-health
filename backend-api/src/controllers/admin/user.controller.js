const User = require("../../models/User");
const UserProfile = require("../../models/UserProfile");
const HealthRecord = require("../../models/HealthRecord");

exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find().select("-password").lean();

    const usersWithProfiles = await Promise.all(
      users.map(async (user) => {
        const profile = await UserProfile.findOne({
          userId: user._id,
        });

        return {
          ...user,
          profile,
        };
      })
    );

    res.status(200).json({
      success: true,
      count: usersWithProfiles.length,
      users: usersWithProfiles,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch users",
    });
  }
};

// GET /api/users/:userId/records
exports.getUserHealthRecords = async (req, res) => {
  try {
    const { userId } = req.params;

    // Fetch targeted user basic info
    const user = await User.findById(userId).select("name email").lean();
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Fetch profile info for extra context if needed
    const profile = await UserProfile.findOne({ userId }).lean();

    // Fetch all health telemetry records for this user
    const records = await HealthRecord.find({ userId })
      .sort({ date: -1 })
      .lean();

    res.status(200).json({
      success: true,
      user: {
        ...user,
        profile,
      },
      count: records.length,
      records,
    });
  } catch (error) {
    console.error("Error fetching user health records:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch user health records",
    });
  }
};