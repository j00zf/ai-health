const mongoose = require("mongoose");

const connectDB = async () => {
  try {
    console.log("================================");
    console.log("Connecting to MongoDB...");
    console.log("Mongo URI:", process.env.MONGO_URI);
    console.log("================================");

    const conn = await mongoose.connect(
      process.env.MONGO_URI,
      {
        serverSelectionTimeoutMS: 10000,
      }
    );

    console.log("================================");
    console.log(`MongoDB Connected`);
    console.log(`Host: ${conn.connection.host}`);
    console.log(`Database: ${conn.connection.name}`);
    console.log("================================");

  } catch (error) {
    console.error("================================");
    console.error("MONGODB CONNECTION ERROR");
    console.error("Name:", error.name);
    console.error("Message:", error.message);
    console.error("Code:", error.code);
    console.error("Reason:", error.reason);
    console.error("Stack:");
    console.error(error.stack);
    console.error("================================");

    process.exit(1);
  }
};

module.exports = connectDB;