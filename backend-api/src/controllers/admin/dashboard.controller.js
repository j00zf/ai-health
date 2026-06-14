const User = require("../../models/User");
const Admin = require("../../models/Admin");
const UserProfile = require("../../models/UserProfile");

exports.getDashboardStats =
  async (req, res) => {
    try {
      const totalUsers =
        await User.countDocuments();

      const totalAdmins =
        await Admin.countDocuments();

      const completedProfiles =
        await UserProfile.countDocuments();

      const fitbitConnected =
        await UserProfile.countDocuments({
          fitbitConnected: true,
        });

      res.status(200).json({
        success: true,

        stats: {
          totalUsers,
          totalAdmins,
          completedProfiles,
          fitbitConnected,
        },
      });
    } catch (error) {
      console.error(error);

      res.status(500).json({
        success: false,
        message:
          "Failed to load dashboard",
      });
    }
  };