const bcrypt = require("bcryptjs");

const Admin = require("../models/Admin");
const generateToken = require("../utils/generateToken");

// =========================
// Register Admin
// =========================
exports.registerAdmin = async (
  req,
  res
) => {
  try {
    console.log(
      "Register Request:",
      req.body
    );

    const {
      name,
      email,
      password,
    } = req.body;

    const existing =
      await Admin.findOne({
        email,
      });

    if (existing) {
      return res.status(400).json({
        success: false,
        message:
          "Email already exists",
      });
    }

    const hashedPassword =
      await bcrypt.hash(
        password,
        10
      );

    const admin =
      await Admin.create({
        name,
        email,
        password:
          hashedPassword,
      });

    console.log(
      "Admin Created:",
      admin._id
    );

    res.status(201).json({
      success: true,
      message:
        "Admin Registered Successfully",
    });

  } catch (error) {
    console.error(
      "========== REGISTER ERROR =========="
    );
    console.error(error);
    console.error(
      "Message:",
      error.message
    );
    console.error(
      "Stack:",
      error.stack
    );
    console.error(
      "===================================="
    );

    res.status(500).json({
      success: false,
      message:
        error.message ||
        "Registration Failed",
    });
  }
};

// =========================
// Login Admin
// =========================
exports.loginAdmin = async (
  req,
  res
) => {
  try {
    console.log(
      "========== LOGIN START =========="
    );

    console.log(
      "Request Body:",
      req.body
    );

    const {
      email,
      password,
    } = req.body;

    const admin =
      await Admin.findOne({
        email,
      });

    console.log(
      "Admin Found:",
      !!admin
    );

    if (!admin) {
      return res.status(400).json({
        success: false,
        message:
          "Invalid Credentials",
      });
    }

    const valid =
      await bcrypt.compare(
        password,
        admin.password
      );

    console.log(
      "Password Match:",
      valid
    );

    if (!valid) {
      return res.status(400).json({
        success: false,
        message:
          "Invalid Credentials",
      });
    }

    console.log(
      "Generating Token..."
    );

    const token =
      generateToken(
        admin._id
      );

    console.log(
      "Token Generated Successfully"
    );

    res.status(200).json({
      success: true,
      token,
      admin: {
        id: admin._id,
        name: admin.name,
        email: admin.email,
      },
    });

    console.log(
      "========== LOGIN SUCCESS =========="
    );

  } catch (error) {
    console.error(
      "========== LOGIN ERROR =========="
    );
    console.error(error);
    console.error(
      "Message:",
      error.message
    );
    console.error(
      "Stack:",
      error.stack
    );
    console.error(
      "================================="
    );

    res.status(500).json({
      success: false,
      message:
        error.message ||
        "Login Failed",
    });
  }
};