const FitbitData = require("../models/FitbitData");
const DeviceConnection = require("../models/DeviceConnection");

// Sync daily data
exports.syncDailyData = async (req, res) => {
  try {
    const { date, steps, heartRate, sleep, caloriesOut } = req.body;

    const data = await FitbitData.findOneAndUpdate(
      { userId: req.user.id, date },
      {
        userId: req.user.id,
        date,
        steps: steps || 0,
        heartRate: heartRate || {},
        sleep: sleep || {},
        caloriesOut: caloriesOut || 0,
        syncedAt: new Date(),
      },
      { upsert: true, new: true }
    );

    res.status(200).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get user's Fitbit data
exports.getFitbitData = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const query = { userId: req.user.id };

    if (startDate && endDate) {
      query.date = { $gte: startDate, $lte: endDate };
    }

    const data = await FitbitData.find(query).sort({ date: -1 });
    res.status(200).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};