// controllers/userProfileController.js

const User = require("../models/User");
const UserProfile = require("../models/UserProfile");
exports.createProfile = async (
  req,
  res
) => {
  try {

    const {
      nickname,
      age,
      gender,
      height,
      weight,
      activityLevel,
      healthGoal,
    } = req.body;

    const existingProfile =
      await UserProfile.findOne({
        userId: req.user.id,
      });

    if (existingProfile) {
      return res.status(400).json({
        success: false,
        message:
          "Profile already exists",
      });
    }

    const bmi =
      weight /
      Math.pow(height / 100, 2);

    const profile =
      await UserProfile.create({
        userId: req.user.id,
        nickname,
        age,
        gender,
        height,
        weight,
        bmi: Number(
          bmi.toFixed(2)
        ),
        activityLevel,
        healthGoal,
      });

    await User.findByIdAndUpdate(
      req.user.id,
      {
        profileCompleted: true,
      }
    );

    res.status(201).json({
      success: true,
      profile,
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: error.message,
    });

  }
};exports.getUserProfile =
  async (req, res) => {

  try {

    const profile =
      await UserProfile.findOne({
        userId: req.user.id,
      });

    if (!profile) {
      return res.status(404).json({
        success: false,
        message:
          "Profile not found",
      });
    }

    res.status(200).json({
      success: true,
      profile,
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: error.message,
    });

  }
};exports.updateProfile =
  async (req, res) => {

  try {

    const profile =
      await UserProfile.findOne({
        userId: req.user.id,
      });

    if (!profile) {
      return res.status(404).json({
        success: false,
        message:
          "Profile not found",
      });
    }

    Object.assign(
      profile,
      req.body
    );

    if (
      profile.height &&
      profile.weight
    ) {
      profile.bmi =
        Number(
          (
            profile.weight /
            Math.pow(
              profile.height / 100,
              2
            )
          ).toFixed(2)
        );
    }

    await profile.save();

    res.status(200).json({
      success: true,
      profile,
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: error.message,
    });

  }
};


