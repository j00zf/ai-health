const HealthRecord = require("../../models/HealthRecord");

exports.getAllHealthRecords = async (req, res) => {
  try {
    const records = await HealthRecord.find({}, {
      userId: 0,
      __v: 0,
      syncedAt: 0,
      createdAt: 0,
      updatedAt: 0
    }).sort({ date: -1 }).lean();

    return res.status(200).json({
      success: true,
      summary: { totalRecords: records.length },
      records,
    });
  } catch (error) {
    console.error("Error loading ML training dataset:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
};