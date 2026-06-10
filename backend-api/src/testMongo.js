const mongoose = require("mongoose");
require("dotenv").config();

async function test() {
  try {
    console.log("Connecting...");

    await mongoose.connect(process.env.MONGO_URI);

    console.log("SUCCESS!");
    console.log("Database:", mongoose.connection.name);
    console.log("Host:", mongoose.connection.host);
    console.log("Database:", client.db().databaseName);
    process.exit(0);
  } catch (err) {
    console.error("FAILED");
    console.error(err);
    process.exit(1);
  }
}

test();