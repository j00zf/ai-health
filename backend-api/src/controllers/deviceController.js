const DeviceConnection = require("../models/DeviceConnection");
const UserProfile = require("../models/UserProfile");

// Connect Fitbit
exports.connectFitbit = async (req, res) => {
  try {
    const { accessToken, refreshToken, expiresIn, fitbitUserId } = req.body;

    let connection = await DeviceConnection.findOne({
      userId: req.user.id,
      deviceType: "fitbit",
    });

    if (connection) {
      connection.accessToken = accessToken;
      connection.refreshToken = refreshToken;
      connection.expiresAt = new Date(Date.now() + expiresIn * 1000);
      connection.fitbitUserId = fitbitUserId;
      connection.connected = true;
    } else {
      connection = await DeviceConnection.create({
        userId: req.user.id,
        deviceType: "fitbit",
        accessToken,
        refreshToken,
        expiresAt: new Date(Date.now() + expiresIn * 1000),
        fitbitUserId,
        connected: true,
      });
    }

    // Update profile
    await UserProfile.findOneAndUpdate(
      { userId: req.user.id },
      { fitbitConnected: true }
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