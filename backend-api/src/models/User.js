const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
{
  name: {
    type: String,
    required: true,
  },

  email: {
    type: String,
    required: true,
    unique: true,
  },

  phone: {
    type: String,
    default: "",
  },

  password: {
    type: String,
    default: null,
  },

  authProvider: {
    type: String,
    enum: ["local", "google"],
    default: "local",
  },

  firebaseUid: {
    type: String,
    default: null,
  },

  photoUrl: {
    type: String,
    default: "",
  },

  lastLogin: {
    type: Date,
    default: Date.now,
  },

  profileCompleted: {
    type: Boolean,
    default: false,
  },

  profileId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "UserProfile",
    default: null,
  },

},
{
  timestamps: true,
});

module.exports = mongoose.model(
  "User",
  userSchema
);