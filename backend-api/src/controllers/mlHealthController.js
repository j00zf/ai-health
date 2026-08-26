const {
    analyzeWithPulseAI,
    checkPulseAiHealth,
} = require(
    "../services/mlPulseAiService"
);


// ============================================================
// ANALYZE
// ============================================================

async function analyzeMlHealth(
    req,
    res
) {

    try {

        const {
            profile,
            health_records,
        } = req.body;


        // ----------------------------------------------------
        // Validate profile
        // ----------------------------------------------------

        if (
            !profile ||
            typeof profile !== "object"
        ) {

            return res.status(400).json({

                success:
                    false,

                message:
                    "profile is required",

            });
        }


        // ----------------------------------------------------
        // Validate records
        // ----------------------------------------------------

        if (
            health_records !== undefined &&
            !Array.isArray(
                health_records
            )
        ) {

            return res.status(400).json({

                success:
                    false,

                message:
                    "health_records must be an array",

            });
        }


        // ----------------------------------------------------
        // Python ML service
        // ----------------------------------------------------

        const result =
            await analyzeWithPulseAI(

                profile,

                health_records || []

            );


        // ----------------------------------------------------
        // Return
        // ----------------------------------------------------

        return res.status(200).json({

            success:
                true,

            source:
                "pulse-ai",

            data:
                result,

        });

    } catch (error) {

        console.error(
            "ML health analysis error:",
            error
        );


        return res.status(503).json({

            success:
                false,

            message:
                "Pulse AI analysis service is unavailable",

            error:
                error.message,

        });
    }
}


// ============================================================
// ML SERVICE HEALTH
// ============================================================

async function getMlHealthStatus(
    req,
    res
) {

    try {

        const result =
            await checkPulseAiHealth();


        if (!result.available) {

            return res.status(503).json({

                success:
                    false,

                service:
                    "pulse-ai",

                available:
                    false,

                error:
                    result.error,

            });
        }


        return res.status(200).json({

            success:
                true,

            service:
                "pulse-ai",

            available:
                true,

            status:
                result.status,

            data:
                result.data,

        });

    } catch (error) {

        return res.status(503).json({

            success:
                false,

            service:
                "pulse-ai",

            available:
                false,

            error:
                error.message,

        });
    }
}


// ============================================================
// EXPORT
// ============================================================

module.exports = {

    analyzeMlHealth,

    getMlHealthStatus,
};