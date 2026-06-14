const bcrypt = require("bcryptjs");

const Admin = require("../../models/Admin");
const generateToken = require("../../utils/generateToken");

// =========================
// Register Admin
// =========================
exports.registerAdmin = async (
  req,
  res
) => {
  try {
    console.log(
      "========== REGISTER START =========="
    );

    console.log(
      "Register Request:",
      req.body
    );

    const {
      name,
      email,
      password,
    } = req.body;

    // Validation
    if (
      !name ||
      !email ||
      !password
    ) {
      return res.status(400).json({
        success: false,
        message:
          "All fields are required",
      });
    }

    // Check existing admin
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

    // Hash password
    const hashedPassword =
      await bcrypt.hash(
        password,
        10
      );

    // Create admin
    const admin =
      await Admin.create({
        name,
        email,
        password:
          hashedPassword,

        // New fields
        status:
          "inactive",
        lastLogin: null,
      });

    console.log(
      "Admin Created:",
      admin._id
    );

    res.status(201).json({
      success: true,
      message:
        "Admin registered successfully. Waiting for activation.",
      admin: {
        id: admin._id,
        name: admin.name,
        email: admin.email,
        status:
          admin.status,
      },
    });

    console.log(
      "========== REGISTER SUCCESS =========="
    );
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

    // Validation
    if (
      !email ||
      !password
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Email and password are required",
      });
    }

    // Find admin
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

    // Check password
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

    // Check account status
    if (
      admin.status !==
      "active"
    ) {
      return res.status(403).json({
        success: false,
        message:
          "Your account is inactive. Please contact the system administrator.",
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

    // Update last login
    admin.lastLogin =
      new Date();

    await admin.save();

    res.status(200).json({
      success: true,
      message:
        "Login successful",
      token,
      admin: {
        id: admin._id,
        name: admin.name,
        email: admin.email,
        status:
          admin.status,
        lastLogin:
          admin.lastLogin,
        createdAt:
          admin.createdAt,
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

// =========================
// Get Current Admin
// =========================
exports.getProfile = async (
  req,
  res
) => {
  try {
    const admin =
      await Admin.findById(
        req.admin.id
      ).select(
        "-password"
      );

    if (!admin) {
      return res.status(404).json({
        success: false,
        message:
          "Admin not found",
      });
    }

    res.status(200).json({
      success: true,
      admin,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message:
        "Failed to fetch profile",
    });
  }
};