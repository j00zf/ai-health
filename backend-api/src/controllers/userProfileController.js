const User = require("../models/User");
const UserProfile = require("../models/UserProfile");

// ============================================================================
// HELPERS
// ============================================================================

function calculateAge(dateOfBirth) {
  if (!dateOfBirth) {
    return null;
  }

  const dob = new Date(dateOfBirth);

  if (Number.isNaN(dob.getTime())) {
    return null;
  }

  const today = new Date();

  let age =
    today.getFullYear() -
    dob.getFullYear();

  const monthDifference =
    today.getMonth() -
    dob.getMonth();

  if (
    monthDifference < 0 ||
    (
      monthDifference === 0 &&
      today.getDate() < dob.getDate()
    )
  ) {
    age--;
  }

  if (age < 0 || age > 150) {
    return null;
  }

  return age;
}

function calculateBMI(height, weight) {
  if (
    !height ||
    !weight ||
    height <= 0 ||
    weight <= 0
  ) {
    return 0;
  }

  const heightMeters = height / 100;

  return Number(
    (
      weight /
      Math.pow(heightMeters, 2)
    ).toFixed(2)
  );
}

// ============================================================================
// CREATE PROFILE
// ============================================================================

exports.createProfile = async (req, res) => {
  try {
    const {
      nickname,
      dateOfBirth,
      age,
      sex,
      gender,
      bloodGroup,

      height,
      weight,
      waistCircumference,

      activityLevel,
      dietaryPreference,
      sleepTargetHours,
      smokingStatus,
      alcoholConsumption,

      allergies,
      medicalConditions,
      medications,

      healthGoal,
    } = req.body;

    // ------------------------------------------------------------------------
    // Check whether profile already exists
    // ------------------------------------------------------------------------

    const existingProfile =
      await UserProfile.findOne({
        userId: req.user.id,
      });

    if (existingProfile) {
      return res.status(400).json({
        success: false,
        message: "Profile already exists",
      });
    }

    // ------------------------------------------------------------------------
    // Calculate age
    // ------------------------------------------------------------------------

    const calculatedAge =
      calculateAge(dateOfBirth) ??
      age ??
      null;

    // ------------------------------------------------------------------------
    // Calculate BMI
    // ------------------------------------------------------------------------

    const bmi =
      calculateBMI(
        Number(height),
        Number(weight)
      );

    // ------------------------------------------------------------------------
    // Create profile
    // ------------------------------------------------------------------------

    const profile =
      await UserProfile.create({
        userId: req.user.id,

        nickname,

        dateOfBirth:
          dateOfBirth || null,

        age: calculatedAge,

        sex: sex || gender || null,

        gender:
          gender || sex || null,

        bloodGroup:
          bloodGroup || "Unknown",

        height:
          height != null
            ? Number(height)
            : null,

        weight:
          weight != null
            ? Number(weight)
            : null,

        waistCircumference:
          waistCircumference != null
            ? Number(waistCircumference)
            : null,

        bmi,

        activityLevel:
          activityLevel ||
          "Sedentary",

        dietaryPreference:
          dietaryPreference ||
          "No Preference",

        sleepTargetHours:
          sleepTargetHours != null
            ? Number(sleepTargetHours)
            : null,

        smokingStatus:
          smokingStatus || "No",

        alcoholConsumption:
          alcoholConsumption || "No",

        allergies:
          allergies || "",

        medicalConditions:
          medicalConditions || "",

        medications:
          medications || "",

        healthGoal:
          healthGoal ||
          "Improve Fitness",
      });

    // ------------------------------------------------------------------------
    // Mark profile as completed
    // ------------------------------------------------------------------------

    await User.findByIdAndUpdate(
      req.user.id,
      {
        profileCompleted: true,
        profileId: profile._id,
      }
    );

    return res.status(201).json({
      success: true,
      message: "Profile created successfully",
      profile,
    });
  } catch (error) {
    console.error(
      "[Profile] Create error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================================
// GET CURRENT USER PROFILE
// ============================================================================

exports.getUserProfile = async (
  req,
  res
) => {
  try {
    const profile =
      await UserProfile.findOne({
        userId: req.user.id,
      }).lean();

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: "Profile not found",
      });
    }

    return res.status(200).json({
      success: true,
      profile,
    });
  } catch (error) {
    console.error(
      "[Profile] Get error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================================
// UPDATE CURRENT USER PROFILE
// ============================================================================

exports.updateProfile = async (
  req,
  res
) => {
  try {
    const profile =
      await UserProfile.findOne({
        userId: req.user.id,
      });

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: "Profile not found",
      });
    }

    // ------------------------------------------------------------------------
    // Only these fields may be changed from the profile screen.
    // ------------------------------------------------------------------------

    const allowedFields = [
      "nickname",
      "dateOfBirth",
      "sex",
      "gender",
      "bloodGroup",

      "height",
      "weight",
      "waistCircumference",

      "activityLevel",
      "dietaryPreference",
      "sleepTargetHours",
      "smokingStatus",
      "alcoholConsumption",

      "allergies",
      "medicalConditions",
      "medications",

      "healthGoal",
    ];

    for (const field of allowedFields) {
      if (
        Object.prototype.hasOwnProperty.call(
          req.body,
          field
        )
      ) {
        profile[field] =
          req.body[field];
      }
    }

    // ------------------------------------------------------------------------
    // Keep sex and gender synchronized.
    // ------------------------------------------------------------------------

    if (req.body.sex) {
      profile.sex = req.body.sex;
      profile.gender = req.body.sex;
    } else if (req.body.gender) {
      profile.gender = req.body.gender;
      profile.sex = req.body.gender;
    }

    // ------------------------------------------------------------------------
    // Recalculate age from DOB.
    // Never trust the age sent by Flutter.
    // ------------------------------------------------------------------------

    if (profile.dateOfBirth) {
      profile.age =
        calculateAge(
          profile.dateOfBirth
        );
    }

    // ------------------------------------------------------------------------
    // Recalculate BMI from height + weight.
    // ------------------------------------------------------------------------

    profile.bmi =
      calculateBMI(
        Number(profile.height),
        Number(profile.weight)
      );

    await profile.save();

    // ------------------------------------------------------------------------
    // Keep User profile completion state synchronized.
    // ------------------------------------------------------------------------

    await User.findByIdAndUpdate(
      req.user.id,
      {
        profileCompleted: true,
        profileId: profile._id,
      }
    );

    return res.status(200).json({
      success: true,
      message: "Profile updated successfully",
      profile,
    });
  } catch (error) {
    console.error(
      "[Profile] Update error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};