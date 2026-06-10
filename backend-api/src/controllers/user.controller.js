const bcrypt = require("bcryptjs");

const User = require("../models/User");
const generateToken = require("../utils/generateToken");

// Register
exports.registerUser = async (
  req,
  res
) => {
  try {
    const {
      name,
      email,
      phone,
      password,
    } = req.body;

    const existing =
      await User.findOne({
        email,
      });

    if (existing) {
      return res.status(400).json({
        message:
          "User already exists",
      });
    }

    const hashed =
      await bcrypt.hash(
        password,
        10
      );

    const user =
      await User.create({
        name,
        email,
        phone,
        password: hashed,
      });

    res.status(201).json({
      success: true,
      message:
        "Account created successfully",
    });

  } catch (error) {
    console.log(error);

    res.status(500).json({
      message: error.message,
    });
  }
};

// Login
exports.loginUser = async (
  req,
  res
) => {
  try {
    const {
      email,
      password,
    } = req.body;

    const user =
      await User.findOne({
        email,
      });

    if (!user) {
      return res.status(400).json({
        message:
          "Invalid credentials",
      });
    }

    const valid =
      await bcrypt.compare(
        password,
        user.password
      );

    if (!valid) {
      return res.status(400).json({
        message:
          "Invalid credentials",
      });
    }

    const token =
      generateToken(
        user._id
      );

    res.json({
      success: true,
      token,

      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
      },
    });

  } catch (error) {
    console.log(error);

    res.status(500).json({
      message: error.message,
    });
  }
};