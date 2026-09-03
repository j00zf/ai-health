// ============================================================================
// controllers/aiController.js
// Pulse AI Controller
//
// Uses:
//   - MongoDB for users, profiles, health data and conversations
//   - Groq API for AI generation
//   - Llama 3.3 70B Versatile
//
// Flutter flow:
//
//   Flutter
//      ↓
//   POST /api/ai/chat
//      ↓
//   Node.js
//      ↓
//   MongoDB → User + Profile + Health Data + Conversation
//      ↓
//   Groq
//      ↓
//   Llama 3.3 70B
//      ↓
//   MongoDB
//      ↓
//   Flutter
// ============================================================================

const OpenAI = require("openai");

const User = require("../models/User");
const UserProfile = require("../models/UserProfile");
const HealthRecord = require("../models/HealthRecord");
const AIConversation = require("../models/AIConversation");

// ============================================================================
// GROQ CONFIGURATION
// ============================================================================

const GROQ_API_KEY = process.env.GROQ_API_KEY;

const GROQ_MODEL =
  process.env.GROQ_MODEL ||
  "llama-3.1-70b-versatile";

if (!GROQ_API_KEY) {
  console.warn(
    "[AI] WARNING: GROQ_API_KEY is not configured."
  );
}

// Groq provides an OpenAI-compatible API.
const groq = new OpenAI({
  apiKey: GROQ_API_KEY,
  baseURL: "https://api.groq.com/openai/v1",
});

// ============================================================================
// HEALTH DATA FORMATTER
// ============================================================================

function cleanHealthRecord(record) {
  if (!record) {
    return null;
  }

  return {
    date: record.date ?? null,

    activity: {
      steps: record.steps ?? 0,

      distanceWalkedKm:
        record.distanceWalked ?? 0,

      calories:
        record.calories ?? 0,

      activeHours:
        record.activeHours ?? 0,

      floors:
        record.floors ?? 0,

      activeZoneMinutes:
        record.activeZoneMinutes ?? 0,
    },

    heart: {
      heartRate:
        record.heartRate ?? 0,

      restingHeartRate:
        record.restingHeartRate ?? 0,
    },

    sleep: {
      sleepHours:
        record.sleepHours ?? 0,
    },

    measurements: {
      bloodOxygen:
        record.bloodOxygen ?? 0,

      bodyTemperature:
        record.bodyTemperature ?? 0,

      weightKg:
        record.weight ?? 0,
    },

    source:
      record.source ?? "Unknown",

    syncedAt:
      record.syncedAt ?? null,
  };
}

// ============================================================================
// SYSTEM PROMPT
// ============================================================================

function buildSystemPrompt(profile, healthData) {
  return `
You are Pulse AI, a personal health information assistant.

Your purpose is to help users understand their personal health,
fitness, sleep, activity and wearable data.

You are powered by an AI language model and are NOT a doctor.

======================================================================
IMPORTANT HEALTH SAFETY RULES
======================================================================

1. Do not diagnose diseases.

2. Do not tell the user that they definitely have a medical condition.

3. Do not prescribe medication.

4. Do not recommend changing medication dosage.

5. Do not invent health measurements.

6. Only refer to health metrics that are actually provided.

7. Clearly distinguish measured data from general health information.

8. If the provided data could potentially be concerning, recommend
   discussing it with a qualified healthcare professional.

9. If the user describes severe symptoms or a possible emergency,
   recommend seeking immediate medical attention.

10. Do not unnecessarily frighten the user.

11. Use simple and understandable language.

12. If the user asks something unrelated to health, you can still answer
    normally, but do not pretend that unrelated information comes from
    their health records.

======================================================================
HOW TO USE HEALTH DATA
======================================================================

When a user's question is related to their health:

- Look at the supplied health metrics.
- Use the actual values in your explanation.
- Mention the relevant measurements.
- Do not make up missing values.
- If a metric is unavailable, say that it is not available.
- Do not confuse heart rate with resting heart rate.
- Do not treat wearable measurements as a medical diagnosis.

For example, if the health data says:

steps = 8432
sleepHours = 7.2
restingHeartRate = 64

and the user asks:

"How was my activity today?"

You should refer to the 8,432 steps when appropriate.

If the user asks:

"How was my sleep?"

You should refer to the 7.2 hours of sleep.

======================================================================
USER PROFILE
======================================================================

${JSON.stringify(
  profile || {},
  null,
  2
)}

======================================================================
LATEST HEALTH DATA
======================================================================

${JSON.stringify(
  healthData || {},
  null,
  2
)}

======================================================================
RESPONSE STYLE
======================================================================

- Be concise but useful.
- Use short paragraphs.
- Use bullet points when they improve readability.
- Explain numbers in plain language.
- Avoid unnecessary medical terminology.
- Never claim certainty about a diagnosis.
- Do not invent information.

Always answer the user's actual question.
`;
}

// ============================================================================
// CREATE NEW CONVERSATION
// ============================================================================

exports.createConversation = async (req, res) => {
  try {
    const conversation =
      await AIConversation.create({
        userId: req.user.id,

        title: "New Health Chat",

        messages: [],

        lastMessageAt: new Date(),
      });

    return res.status(201).json({
      success: true,
      conversation,
    });
  } catch (error) {
    console.error(
      "[AI] Create conversation error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        error.message ||
        "Failed to create conversation",
    });
  }
};

// ============================================================================
// GET ALL USER CONVERSATIONS
// ============================================================================

exports.getConversations = async (
  req,
  res
) => {
  try {
    const conversations =
      await AIConversation.find({
        userId: req.user.id,
      })
        .select(
          "_id title lastMessageAt createdAt updatedAt messages"
        )
        .sort({
          lastMessageAt: -1,
        })
        .limit(50)
        .lean();

    const result =
      conversations.map(
        (conversation) => ({
          id: conversation._id,

          title:
            conversation.title ||
            "Health Chat",

          lastMessageAt:
            conversation.lastMessageAt,

          createdAt:
            conversation.createdAt,

          messageCount:
            conversation.messages
              ?.length || 0,

          preview:
            conversation.messages
                ?.length > 0
              ? conversation.messages[
                  conversation.messages
                    .length - 1
                ].content
              : "",
        })
      );

    return res.status(200).json({
      success: true,
      conversations: result,
    });
  } catch (error) {
    console.error(
      "[AI] Get conversations error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        error.message ||
        "Failed to load conversations",
    });
  }
};

// ============================================================================
// GET ONE CONVERSATION
// ============================================================================

exports.getConversation = async (
  req,
  res
) => {
  try {
    const conversation =
      await AIConversation.findOne({
        _id: req.params.id,

        userId: req.user.id,
      }).lean();

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message:
          "Conversation not found",
      });
    }

    return res.status(200).json({
      success: true,
      conversation,
    });
  } catch (error) {
    console.error(
      "[AI] Get conversation error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        error.message ||
        "Failed to load conversation",
    });
  }
};

// ============================================================================
// DELETE CONVERSATION
// ============================================================================

exports.deleteConversation = async (
  req,
  res
) => {
  try {
    const result =
      await AIConversation.findOneAndDelete({
        _id: req.params.id,

        userId: req.user.id,
      });

    if (!result) {
      return res.status(404).json({
        success: false,
        message:
          "Conversation not found",
      });
    }

    return res.status(200).json({
      success: true,
      message:
        "Conversation deleted successfully",
    });
  } catch (error) {
    console.error(
      "[AI] Delete conversation error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        error.message ||
        "Failed to delete conversation",
    });
  }
};

// ============================================================================
// SEND MESSAGE TO GROQ
// ============================================================================

exports.sendMessage = async (
  req,
  res
) => {
  try {
    const {
      message,
      conversationId,
    } = req.body;

    // ------------------------------------------------------------------------
    // VALIDATE MESSAGE
    // ------------------------------------------------------------------------

    if (
      !message ||
      typeof message !== "string" ||
      !message.trim()
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Message is required",
      });
    }

    // ------------------------------------------------------------------------
    // CHECK GROQ CONFIGURATION
    // ------------------------------------------------------------------------

    if (!GROQ_API_KEY) {
      console.error(
        "[AI] GROQ_API_KEY is missing"
      );

      return res.status(503).json({
        success: false,
        message:
          "AI service is not configured on the server.",
      });
    }

    // ------------------------------------------------------------------------
    // USER
    // ------------------------------------------------------------------------

    const user =
      await User.findById(
        req.user.id
      )
        .select("-password")
        .lean();

    if (!user) {
      return res.status(404).json({
        success: false,
        message:
          "User not found",
      });
    }

    // ------------------------------------------------------------------------
    // USER PROFILE
    // ------------------------------------------------------------------------

    const profile =
      await UserProfile.findOne({
        userId: req.user.id,
      }).lean();

    // ------------------------------------------------------------------------
    // LATEST HEALTH RECORD
    // ------------------------------------------------------------------------

    const latestRecord =
      await HealthRecord.findOne({
        userId: req.user.id,
      })
        .sort({
          date: -1,
        })
        .lean();

    const healthData =
      cleanHealthRecord(
        latestRecord
      );

    // ------------------------------------------------------------------------
    // GET OR CREATE CONVERSATION
    // ------------------------------------------------------------------------

    let conversation = null;

    if (conversationId) {
      conversation =
        await AIConversation.findOne({
          _id: conversationId,

          userId: req.user.id,
        });
    }

    if (!conversation) {
      conversation =
        await AIConversation.create({
          userId: req.user.id,

          title:
            message
              .trim()
              .substring(0, 60),

          messages: [],

          lastMessageAt:
            new Date(),
        });
    }

    // ------------------------------------------------------------------------
    // STORE USER MESSAGE
    // ------------------------------------------------------------------------

    conversation.messages.push({
      role: "user",

      content:
        message.trim(),
    });

    // ------------------------------------------------------------------------
    // SYSTEM PROMPT
    // ------------------------------------------------------------------------

    const systemPrompt =
      buildSystemPrompt(
        {
          name: user.name,

          email: user.email,

          profile,
        },

        healthData
      );

    // ------------------------------------------------------------------------
    // RECENT CONVERSATION
    //
    // Keep only the last 20 messages so the request doesn't become
    // unnecessarily large.
    // ------------------------------------------------------------------------

    const recentMessages =
      conversation.messages.slice(
        -20
      );

    const groqMessages = [
      {
        role: "system",

        content:
          systemPrompt,
      },

      ...recentMessages.map(
        (msg) => ({
          role: msg.role,

          content:
            msg.content,
        })
      ),
    ];

    // ------------------------------------------------------------------------
    // LOG REQUEST
    // ------------------------------------------------------------------------

    console.log(
      "================================================"
    );

    console.log(
      "[AI] Groq request"
    );

    console.log(
      `[AI] Model: ${GROQ_MODEL}`
    );

    console.log(
      `[AI] User: ${req.user.id}`
    );

    console.log(
      `[AI] Conversation: ${conversation._id}`
    );

    console.log(
      `[AI] Health record: ${
        latestRecord
          ? "available"
          : "not available"
      }`
    );

    console.log(
      "================================================"
    );

    // ------------------------------------------------------------------------
    // CALL GROQ
    // ------------------------------------------------------------------------

    const completion =
      await groq.chat.completions.create(
        {
          model: GROQ_MODEL,

          messages:
            groqMessages,

          temperature: 0.3,

          max_tokens:
            1024,
        }
      );

    // ------------------------------------------------------------------------
    // EXTRACT RESPONSE
    // ------------------------------------------------------------------------

    const assistantReply =
      completion
        ?.choices?.[0]
        ?.message
        ?.content;

    if (
      !assistantReply ||
      typeof assistantReply !==
        "string" ||
      !assistantReply.trim()
    ) {
      console.error(
        "[AI] Groq returned empty response:",
        completion
      );

      return res.status(502).json({
        success: false,
        message:
          "AI returned an empty response.",
      });
    }

    // ------------------------------------------------------------------------
    // STORE AI RESPONSE
    // ------------------------------------------------------------------------

    conversation.messages.push({
      role: "assistant",

      content:
        assistantReply.trim(),
    });

    conversation.lastMessageAt =
      new Date();

    // Save conversation to MongoDB.
    await conversation.save();

    // ------------------------------------------------------------------------
    // RESPONSE TO FLUTTER
    // ------------------------------------------------------------------------

    return res.status(200).json({
      success: true,

      conversationId:
        conversation._id,

      message: {
        role: "assistant",

        content:
          assistantReply.trim(),
      },

      // Useful for debugging / displaying
      // health context if required.
      healthData,

      model: GROQ_MODEL,
    });
  } catch (error) {
    // ------------------------------------------------------------------------
    // GROQ API ERRORS
    // ------------------------------------------------------------------------

    console.error(
      "================================================"
    );

    console.error(
      "[AI] GROQ ERROR"
    );

    console.error(
      "Message:",
      error?.message
    );

    console.error(
      "Status:",
      error?.status
    );

    console.error(
      "Code:",
      error?.code
    );

    console.error(
      "Response:",
      error?.response?.data
    );

    console.error(
      "================================================"
    );

    // ------------------------------------------------------------------------
    // AUTH / API KEY ERROR
    // ------------------------------------------------------------------------

    if (
      error?.status === 401 ||
      error?.code ===
        "invalid_api_key"
    ) {
      return res.status(503).json({
        success: false,

        message:
          "AI service authentication failed. Check the Groq API key.",
      });
    }

    // ------------------------------------------------------------------------
    // RATE LIMIT
    // ------------------------------------------------------------------------

    if (
      error?.status === 429
    ) {
      return res.status(429).json({
        success: false,

        message:
          "AI service rate limit reached. Please try again shortly.",
      });
    }

    // ------------------------------------------------------------------------
    // TIMEOUT
    // ------------------------------------------------------------------------

    if (
      error?.code ===
        "ETIMEDOUT" ||
      error?.code ===
        "ECONNABORTED"
    ) {
      return res.status(504).json({
        success: false,

        message:
          "The AI service took too long to respond. Please try again.",
      });
    }

    // ------------------------------------------------------------------------
    // GENERAL ERROR
    // ------------------------------------------------------------------------

    return res.status(500).json({
      success: false,

      message:
        error?.message ||
        "AI request failed",
    });
  }
};