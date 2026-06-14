const DeviceConnection = require("../models/DeviceConnection");
const UserProfile = require("../models/UserProfile");

// Connect Google Health (Unified Fitbit API)
exports.connectFitbit = async (req, res) => {
  try {
    const { accessToken, refreshToken, expiresIn } = req.body;

    // Convert string inputs safely to track background session windows
    const parsedExpiresIn = parseInt(expiresIn, 10) || 3600; 

    let connection = await DeviceConnection.findOne({
      userId: req.user.id,
      deviceType: "fitbit",
    });

    if (connection) {
      connection.accessToken = accessToken;
      connection.refreshToken = refreshToken || connection.refreshToken; // Retain old refresh token if Google omits it
      connection.expiresAt = new Date(Date.now() + parsedExpiresIn * 1000);
      connection.connected = true;
      await connection.save();
    } else {
      connection = await DeviceConnection.create({
        userId: req.user.id,
        deviceType: "fitbit",
        accessToken,
        refreshToken: refreshToken || "",
        expiresAt: new Date(Date.now() + parsedExpiresIn * 1000), // ← Fixed: Changed '=' to ':'
        connected: true,
      });
    }

    // Update global app profile context flags
    await UserProfile.findOneAndUpdate(
      { userId: req.user.id },
      { fitbitConnected: true },
      { upsert: true }
    );

    res.status(200).json({ success: true, connection });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get connection status
exports.getDevices = async (req, res) => {
  try {
    const devices = await DeviceConnection.find({ userId: req.user.id });
    res.status(200).json({ success: true, devices });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};