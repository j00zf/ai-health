const Admin = require("../../models/Admin");

exports.getAllAdmins =
  async (req, res) => {
    try {
      const admins =
        await Admin.find()
          .select("-password")
          .sort({
            createdAt: -1,
          });

      res.status(200).json({
        success: true,
        count: admins.length,
        admins,
      });
    } catch (error) {
      console.error(error);

      res.status(500).json({
        success: false,
        message:
          "Failed to fetch admins",
      });
    }
  };