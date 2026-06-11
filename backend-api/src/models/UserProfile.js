const mongoose = require("mongoose");

const userProfileSchema = new mongoose.Schema(
{
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    unique: true,
  },

  nickname: {
    type: String,
    required: true,
  },

  age: {
    type: Number,
    required: true,
  },

  gender: {
    type: String,
    enum: [
      "Male",
      "Female",
      "Other",
    ],
    required: true,
  },

  height: {
    type: Number,
    required: true,
  },

  weight: {
    type: Number,
    required: true,
  },

  profileImage: {
    type: String,
    default: "",
  },

  bmi: {
    type: Number,
    default: 0,
  },

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

  healthGoal: {
    type: String,
    enum: [
      "Lose Weight",
      "Maintain Weight",
      "Gain Weight",
      "Improve Fitness",
      "Improve Sleep",
    ],
    default: "Improve Fitness",
  },

},
{
  timestamps: true,
});

module.exports = mongoose.model(
  "UserProfile",
  userProfileSchema
);