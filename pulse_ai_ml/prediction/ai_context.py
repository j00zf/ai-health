from typing import Any, Dict


# ============================================================
# AI CONTEXT BUILDER
# ============================================================

def build_ai_context(
    analysis: Dict[str, Any],
) -> Dict[str, Any]:

    scores = analysis.get(
        "scores",
        {},
    )

    probabilities = analysis.get(
        "modelProbabilities",
        {},
    )

    wellness = analysis.get(
        "wellness",
        {},
    )

    explanation = analysis.get(
        "explanation",
        {},
    )

    recommendations = analysis.get(
        "recommendations",
        {},
    )

    data_quality = analysis.get(
        "dataQuality",
        {},
    )


    # ========================================================
    # Extract windows
    # ========================================================

    windows = wellness.get(
        "windows",
        {},
    )


    # ========================================================
    # Extract signals
    # ========================================================

    signals = wellness.get(
        "signals",
        [],
    )


    # ========================================================
    # Extract dimensions
    # ========================================================

    latest_window = windows.get(
        "7d",
        {},
    )


    dimensions = latest_window.get(
        "dimensions",
        {},
    )


    # ========================================================
    # AI CONTEXT
    # ========================================================

    context = {

        # ----------------------------------------------------
        # SCORE INFORMATION
        # ----------------------------------------------------

        "scores": {

            "heartHealthScore":
                scores.get(
                    "heartHealthScore"
                ),

            "healthScore":
                scores.get(
                    "healthScore"
                ),

            "wellnessBaselineScore":
                scores.get(
                    "wellnessBaselineScore"
                ),

            "personalWellnessScore":
                scores.get(
                    "personalWellnessScore"
                ),

            "overallWellbeingScore":
                scores.get(
                    "overallWellbeingScore"
                ),
        },


        # ----------------------------------------------------
        # MODEL PROBABILITIES
        # ----------------------------------------------------

        "modelProbabilities": {

            "heartOutcomeProbability":
                probabilities.get(
                    "heartOutcomeProbability"
                ),

            "healthOutcomeProbability":
                probabilities.get(
                    "healthOutcomeProbability"
                ),

            "favorableWellnessProbability":
                probabilities.get(
                    "favorableWellnessProbability"
                ),
        },


        # ----------------------------------------------------
        # CURRENT WELLNESS
        # ----------------------------------------------------

        "wellness": {

            "status":
                wellness.get(
                    "status"
                ),

            "baselineScore":
                wellness.get(
                    "baselineScore"
                ),

            "longitudinalScore":
                wellness.get(
                    "longitudinalScore"
                ),

            "personalWellnessScore":
                wellness.get(
                    "personalWellnessScore"
                ),
        },


        # ----------------------------------------------------
        # 7-DAY DIMENSIONS
        # ----------------------------------------------------

        "currentDimensions":
            dimensions,


        # ----------------------------------------------------
        # LONGITUDINAL WINDOWS
        # ----------------------------------------------------

        "longitudinalWindows": {

            "7d":
                windows.get(
                    "7d"
                ),

            "14d":
                windows.get(
                    "14d"
                ),

            "30d":
                windows.get(
                    "30d"
                ),
        },


        # ----------------------------------------------------
        # WELLNESS SIGNALS
        # ----------------------------------------------------

        "signals":
            signals,


        # ----------------------------------------------------
        # EXPLAINABILITY
        # ----------------------------------------------------

        "explanation": {

            "trend":
                explanation.get(
                    "trendExplanation"
                ),

            "positiveSummary":
                explanation.get(
                    "positiveSummary"
                ),

            "attentionSummary":
                explanation.get(
                    "attentionSummary"
                ),

            "positiveFactors":
                explanation.get(
                    "positiveFactors",
                    [],
                ),

            "attentionFactors":
                explanation.get(
                    "attentionFactors",
                    [],
                ),
        },


        # ----------------------------------------------------
        # RECOMMENDATIONS
        # ----------------------------------------------------

        "recommendations": {

            "overallMessage":
                recommendations.get(
                    "overallMessage"
                ),

            "trendMessage":
                recommendations.get(
                    "trendMessage"
                ),

            "mainOpportunity":
                recommendations.get(
                    "mainOpportunity"
                ),

            "recommendations":
                recommendations.get(
                    "recommendations",
                    [],
                ),

            "maintenance":
                recommendations.get(
                    "maintenance",
                    [],
                ),
        },


        # ----------------------------------------------------
        # DATA QUALITY
        # ----------------------------------------------------

        "dataQuality":
            data_quality,


        # ----------------------------------------------------
        # SYSTEM CONSTRAINTS
        # ----------------------------------------------------

        "constraints": {

            "doNotDiagnose":
                True,

            "doNotModifyScores":
                True,

            "doNotInventMeasurements":
                True,

            "doNotInventTrends":
                True,

            "doNotInventMedicalHistory":
                True,

            "bloodPressureUsed":
                analysis.get(
                    "bloodPressureUsed",
                    False,
                ),

            "modelVersion":
                analysis.get(
                    "modelVersion",
                    "unknown",
                ),
        },
    }


    return context