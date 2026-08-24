const mongoose = require("mongoose");

const userProfileSchema = new mongoose.Schema(
  {
    // =========================================================================
    // USER
    // =========================================================================

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
      index: true,
    },

    // =========================================================================
    // PERSONAL INFORMATION
    // =========================================================================

    nickname: {
      type: String,
      required: true,
      trim: true,
    },

    dateOfBirth: {
      type: Date,
      default: null,
    },

    // Calculated from dateOfBirth
    age: {
      type: Number,
      default: null,
      min: 0,
      max: 150,
    },

    sex: {
      type: String,
      enum: [
        "Male",
        "Female",
        "Other",
        "Prefer not to say",
      ],
      default: null,
    },

    // Kept for compatibility with the existing application
    gender: {
      type: String,
      enum: [
        "Male",
        "Female",
        "Other",
        "Prefer not to say",
      ],
      default: null,
    },

    bloodGroup: {
      type: String,
      enum: [
        "A+",
        "A-",
        "B+",
        "B-",
        "AB+",
        "AB-",
        "O+",
        "O-",
        "Unknown",
      ],
      default: "Unknown",
    },

    // =========================================================================
    // BODY MEASUREMENTS
    // =========================================================================

    height: {
      type: Number,
      default: null,
      min: 30,
      max: 300,
    },

    weight: {
      type: Number,
      default: null,
      min: 1,
      max: 500,
    },

    waistCircumference: {
      type: Number,
      default: null,
      min: 20,
      max: 300,
    },

    // Automatically calculated from height and weight
    bmi: {
      type: Number,
      default: 0,
    },

    // =========================================================================
    // LIFESTYLE
    // =========================================================================

    activityLevel: {
      type: String,
      enum: [
        "Sedentary",
        "Light",
        "Moderate",
        "Active",
        "Very Active",
      ],
      default: "Sedentary",
    },

    dietaryPreference: {
      type: String,
      enum: [
        "No Preference",
        "Vegetarian",
        "Vegan",
        "Non-Vegetarian",
        "Pescatarian",
      ],
      default: "No Preference",
    },

    sleepTargetHours: {
      type: Number,
      default: null,
      min: 0,
      max: 24,
    },

    smokingStatus: {
      type: String,
      enum: [
        "No",
        "Occasionally",
        "Yes",
      ],
      default: "No",
    },

    alcoholConsumption: {
      type: String,
      enum: [
        "No",
        "Occasionally",
        "Yes",
      ],
      default: "No",
    },

    // =========================================================================
    // HEALTH INFORMATION
    // =========================================================================

    allergies: {
      type: String,
      default: "",
      trim: true,
    },

    medicalConditions: {
      type: String,
      default: "",
      trim: true,
    },

    medications: {
      type: String,
      default: "",
      trim: true,
    },

    // =========================================================================
    // HEALTH GOALS
    // =========================================================================

    healthGoal: {
      type: String,
      enum: [
        "Lose Weight",
        "Maintain Weight",
        "Gain Weight",
        "Improve Fitness",
        "Improve Sleep",
        "General Wellness",
      ],
      default: "Improve Fitness",
    },

    // =========================================================================
    // PROFILE IMAGE
    // =========================================================================

    profileImage: {
      type: String,
      default: "",
    },

    // =========================================================================
    // GOOGLE HEALTH
    // =========================================================================

    healthConnected: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  "UserProfile",
  userProfileSchema
);