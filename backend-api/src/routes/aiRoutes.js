const express = require("express");

const router = express.Router();

const protect = require("../middleware/userAuth");

const {
  createConversation,
  getConversations,
  getConversation,
  deleteConversation,
  sendMessage,
} = require("../controllers/aiController");

/*
|--------------------------------------------------------------------------
| Conversations
|--------------------------------------------------------------------------
*/

router.post(
  "/conversations",
  protect,
  createConversation
);

router.get(
  "/conversations",
  protect,
  getConversations
);

router.get(
  "/conversations/:id",
  protect,
  getConversation
);

router.delete(
  "/conversations/:id",
  protect,
  deleteConversation
);

/*
|--------------------------------------------------------------------------
| Chat
|--------------------------------------------------------------------------
*/

router.post(
  "/chat",
  protect,
  sendMessage
);

module.exports = router;