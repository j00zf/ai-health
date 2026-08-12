const axios = require("axios");

const User = require("../models/User");
const UserProfile = require("../models/UserProfile");
const HealthRecord = require("../models/HealthRecord");
const AIConversation = require("../models/AIConversation");

const OLLAMA_URL =
  process.env.OLLAMA_URL || "http://72.61.190.92:11434";

const OLLAMA_MODEL =
  process.env.OLLAMA_MODEL || "qwen3:4b";

/*
|--------------------------------------------------------------------------
| Health data formatter
|--------------------------------------------------------------------------
*/

function cleanHealthRecord(record) {
  if (!record) {
    return null;
  }

  return {
    date: record.date,

    activity: {
      steps: record.steps ?? 0,
      distanceWalkedKm: record.distanceWalked ?? 0,
      calories: record.calories ?? 0,
      activeHours: record.activeHours ?? 0,
      floors: record.floors ?? 0,
      activeZoneMinutes: record.activeZoneMinutes ?? 0,
    },

    heart: {
      heartRate: record.heartRate ?? 0,
      restingHeartRate: record.restingHeartRate ?? 0,
    },

    sleep: {
      sleepHours: record.sleepHours ?? 0,
    },

    measurements: {
      bloodOxygen: record.bloodOxygen ?? 0,
      bodyTemperature: record.bodyTemperature ?? 0,
      weightKg: record.weight ?? 0,
    },

    source: record.source ?? "Unknown",
    syncedAt: record.syncedAt ?? null,
  };
}

/*
|--------------------------------------------------------------------------
| System prompt
|--------------------------------------------------------------------------
*/

function buildSystemPrompt(profile, healthData) {
  return `
You are Pulse AI, a health information assistant.

Your job is to help users understand their personal health and wearable
data in simple, clear language.

IMPORTANT SAFETY RULES:

1. You are not a doctor.
2. Do not diagnose diseases.
3. Do not claim that a user definitely has a medical condition.
4. Do not prescribe medication or change medication dosage.
5. Do not invent health measurements.
6. Clearly distinguish between measured data and general information.
7. If data could indicate something concerning, recommend speaking with
   a qualified healthcare professional.
8. For emergencies or severe symptoms, advise the user to seek immediate
   medical attention.
9. Do not unnecessarily alarm the user.
10. Use simple language unless the user asks for technical detail.

USER PROFILE:

${JSON.stringify(profile || {}, null, 2)}

LATEST HEALTH DATA:

${JSON.stringify(healthData || {}, null, 2)}

When answering health questions, use the provided health data when relevant.
Do not assume values that are not present.
`;
}

/*
|--------------------------------------------------------------------------
| Create new conversation
|--------------------------------------------------------------------------
*/

exports.createConversation = async (req, res) => {
  try {
    const conversation = await AIConversation.create({
      userId: req.user.id,
      title: "New Health Chat",
      messages: [],
      lastMessageAt: new Date(),
    });

    res.status(201).json({
      success: true,
      conversation,
    });
  } catch (error) {
    console.error("Create AI conversation error:", error);

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| Get user's conversations
|--------------------------------------------------------------------------
*/

exports.getConversations = async (req, res) => {
  try {
    const conversations = await AIConversation.find({
      userId: req.user.id,
    })
      .select("_id title lastMessageAt createdAt updatedAt messages")
      .sort({ lastMessageAt: -1 })
      .limit(50)
      .lean();

    const result = conversations.map((conversation) => ({
      id: conversation._id,
      title: conversation.title,
      lastMessageAt: conversation.lastMessageAt,
      createdAt: conversation.createdAt,
      messageCount: conversation.messages?.length || 0,

      preview:
        conversation.messages?.length > 0
          ? conversation.messages[
              conversation.messages.length - 1
            ].content
          : "",
    }));

    res.status(200).json({
      success: true,
      conversations: result,
    });
  } catch (error) {
    console.error("Get AI conversations error:", error);

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| Get one conversation
|--------------------------------------------------------------------------
*/

exports.getConversation = async (req, res) => {
  try {
    const conversation = await AIConversation.findOne({
      _id: req.params.id,
      userId: req.user.id,
    }).lean();

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    res.status(200).json({
      success: true,
      conversation,
    });
  } catch (error) {
    console.error("Get AI conversation error:", error);

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| Delete conversation
|--------------------------------------------------------------------------
*/

exports.deleteConversation = async (req, res) => {
  try {
    const result = await AIConversation.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id,
    });

    if (!result) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Conversation deleted",
    });
  } catch (error) {
    console.error("Delete AI conversation error:", error);

    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| Send message to Qwen3
|--------------------------------------------------------------------------
*/

exports.sendMessage = async (req, res) => {
  try {
    const { message, conversationId } = req.body;

    if (!message || !message.trim()) {
      return res.status(400).json({
        success: false,
        message: "Message is required",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | User
    |--------------------------------------------------------------------------
    */

    const user = await User.findById(req.user.id)
      .select("-password")
      .lean();

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | Profile
    |--------------------------------------------------------------------------
    */

    const profile = await UserProfile.findOne({
      userId: req.user.id,
    }).lean();

    /*
    |--------------------------------------------------------------------------
    | Latest health record
    |--------------------------------------------------------------------------
    */

    const latestRecord = await HealthRecord.findOne({
      userId: req.user.id,
    })
      .sort({ date: -1 })
      .lean();

    const healthData = cleanHealthRecord(latestRecord);

    /*
    |--------------------------------------------------------------------------
    | Conversation
    |--------------------------------------------------------------------------
    */

    let conversation;

    if (conversationId) {
      conversation = await AIConversation.findOne({
        _id: conversationId,
        userId: req.user.id,
      });
    }

    if (!conversation) {
      conversation = await AIConversation.create({
        userId: req.user.id,
        title: message.trim().substring(0, 60),
        messages: [],
        lastMessageAt: new Date(),
      });
    }

    /*
    |--------------------------------------------------------------------------
    | Save user message
    |--------------------------------------------------------------------------
    */

    conversation.messages.push({
      role: "user",
      content: message.trim(),
    });

    /*
    |--------------------------------------------------------------------------
    | Build conversation for Ollama
    |--------------------------------------------------------------------------
    */

    const systemPrompt = buildSystemPrompt(
      {
        name: user.name,
        profile,
      },
      healthData
    );

    /*
    | Keep only recent messages to avoid excessive context.
    */

    const recentMessages =
      conversation.messages.slice(-20);

    const ollamaMessages = [
      {
        role: "system",
        content: systemPrompt,
      },

      ...recentMessages.map((msg) => ({
        role: msg.role,
        content: msg.content,
      })),
    ];

    /*
    |--------------------------------------------------------------------------
    | Call Ollama
    |--------------------------------------------------------------------------
    */

    console.log(
      `[AI] Sending request to Ollama: ${OLLAMA_URL}`
    );

    const ollamaResponse = await axios.post(
      `${OLLAMA_URL}/api/chat`,
      {
        model: OLLAMA_MODEL,
        messages: ollamaMessages,
        stream: false,

        options: {
          temperature: 0.3,
          num_ctx: 8192,
        },
      },
      {
        timeout: 180000,
        headers: {
          "Content-Type": "application/json",
        },
      }
    );

    const assistantReply =
      ollamaResponse.data?.message?.content;

    if (!assistantReply) {
      throw new Error(
        "Ollama returned an empty response"
      );
    }

    /*
    |--------------------------------------------------------------------------
    | Save AI response
    |--------------------------------------------------------------------------
    */

    conversation.messages.push({
      role: "assistant",
      content: assistantReply,
    });

    conversation.lastMessageAt = new Date();

    await conversation.save();

    /*
    |--------------------------------------------------------------------------
    | Response
    |--------------------------------------------------------------------------
    */

    res.status(200).json({
      success: true,

      conversationId: conversation._id,

      message: {
        role: "assistant",
        content: assistantReply,
      },

      healthData,
    });
  } catch (error) {
    console.error(
      "AI Chat Error:",
      error.response?.data || error.message
    );

    if (
      error.code === "ECONNREFUSED" ||
      error.code === "ETIMEDOUT"
    ) {
      return res.status(503).json({
        success: false,
        message:
          "AI service is currently unavailable. Please try again.",
      });
    }

    res.status(500).json({
      success: false,
      message: error.response?.data?.error ||
        error.message ||
        "AI request failed",
    });
  }
};