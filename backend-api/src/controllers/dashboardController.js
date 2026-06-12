const User = require("../models/User");
const UserProfile = require("../models/UserProfile");

exports.getDashboard = async (req, res) => {
  try {

    const user = await User.findById(
      req.user.id
    ).select("-password");

    const profile =
      await UserProfile.findOne({
        userId: req.user.id,
      });

    res.status(200).json({
      success: true,
      message:
        "Dashboard loaded successfully",

      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          photoUrl: user.photoUrl,
          profileCompleted:
            user.profileCompleted,
        },

        profile: profile,

        stats: {
          steps: 0,
          calories: 0,
          sleep: 0,
        },

        devices: {
          fitbitConnected: false,
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