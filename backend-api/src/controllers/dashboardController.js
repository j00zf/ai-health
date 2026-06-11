// controllers/dashboardController.js

exports.getDashboard = async (req, res) => {
  try {
    // You can later add real stats here (steps, BMI, calories, etc.)

    res.status(200).json({
      success: true,
      message: "Dashboard loaded successfully",
      data: {
        userId: req.user.id,
        stats: {
          steps: 0,
          calories: 0,
          sleep: 0,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};