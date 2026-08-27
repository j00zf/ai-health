const mongoose = require("mongoose");

const mlDimensionSchema = new mongoose.Schema(
    {
        activity: Number,
        sleep: Number,
        recovery: Number,
        cardiovascular: Number,
        body: Number,
        oxygen: Number,
    },
    {
        _id: false,
    }
);

const mlScoreSchema = new mongoose.Schema(
    {
        heartHealthScore: Number,
        healthScore: Number,
        wellnessBaselineScore: Number,
        personalWellnessScore: Number,
        overallWellbeingScore: Number,
    },
    {
        _id: false,
    }
);

const mlForecastSchema = new mongoose.Schema(
    {
        current: Number,
        forecast7d: Number,
        forecast14d: Number,
        forecast30d: Number,
        trajectory: String,
        confidence: Number,
    },
    {
        _id: false,
    }
);

const mlMissingDataSchema = new mongoose.Schema(
    {
        field: String,
        message: String,
        fallbackValue: mongoose.Schema.Types.Mixed,
    },
    {
        _id: false,
    }
);

const mlHealthAnalysisSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true,
        },

        analyzedAt: {
            type: Date,
            default: Date.now,
            index: true,
        },

        sourceRecordDate: {
            type: Date,
            default: null,
        },

        recordsAnalyzed: {
            type: Number,
            default: 0,
        },

        scores: {
            type: mlScoreSchema,
            default: {},
        },

        dimensions: {
            type: mlDimensionSchema,
            default: {},
        },

        forecast: {
            type: mlForecastSchema,
            default: {},
        },

        dataQuality: {
            type: mongoose.Schema.Types.Mixed,
            default: {},
        },

        missingData: {
            type: [mlMissingDataSchema],
            default: [],
        },

        missingDataCount: {
            type: Number,
            default: 0,
        },

        mlResponse: {
            type: mongoose.Schema.Types.Mixed,
            default: {},
        },

        modelVersion: {
            type: String,
            default: "v2-deployment",
        },
    },
    {
        timestamps: true,
    }
);

mlHealthAnalysisSchema.index({
    user: 1,
    analyzedAt: -1,
});

module.exports = mongoose.model(
    "MLHealthAnalysis",
    mlHealthAnalysisSchema
);