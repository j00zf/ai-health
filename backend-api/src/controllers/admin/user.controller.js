const User = require("../../models/User");
const UserProfile = require("../../models/UserProfile");

exports.getAllUsers = async (
  req,
  res
) => {
  try {
    const users =
      await User.find()
        .select("-password")
        .lean();

    const usersWithProfiles =
      await Promise.all(
        users.map(
          async (user) => {

            const profile =
              await UserProfile.findOne({
                userId: user._id,
              });

            console.log(
              "USER:",
              user.name
            );

            console.log(
              "PROFILE:",
              profile
            );

            return {
              ...user,
              profile,
            };
          }
        )
      );

    res.status(200).json({
      success: true,
      count:
        usersWithProfiles.length,
      users:
        usersWithProfiles,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message:
        "Failed to fetch users",
    });
  }
};