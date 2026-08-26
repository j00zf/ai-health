from typing import Any, Dict


# ============================================================
# SCORE WEIGHTS
# ============================================================

HEART_WEIGHT = 0.25

HEALTH_WEIGHT = 0.35

WELLNESS_WEIGHT = 0.40


# ============================================================
# SCORE BANDS
# ============================================================

def score_band(
    score: float
) -> str:

    if score >= 90:

        return "excellent"

    if score >= 75:

        return "good"

    if score >= 60:

        return "fair"

    if score >= 40:

        return "needs_attention"

    return "high_attention"


# ============================================================
# OVERALL SCORE
# ============================================================

def calculate_overall_score(
    heart_score: float,
    health_score: float,
    wellness_score: float,
) -> float:

    overall = (

        heart_score
        * HEART_WEIGHT

        +

        health_score
        * HEALTH_WEIGHT

        +

        wellness_score
        * WELLNESS_WEIGHT
    )


    return round(
        overall,
        2
    )


# ============================================================
# BUILD SCORE RESPONSE
# ============================================================

def build_score_response(
    prediction: Dict[str, Any]
) -> Dict[str, Any]:

    heart_score = float(
        prediction["heart"]["score"]
    )


    health_score = float(
        prediction["health"]["score"]
    )


    wellness_score = float(
        prediction["wellness"]["score"]
    )


    overall_score = (
        calculate_overall_score(

            heart_score,

            health_score,

            wellness_score,
        )
    )


    return {

        "scores": {

            "heartHealthScore":
                heart_score,

            "healthScore":
                health_score,

            "wellnessBaselineScore":
                wellness_score,

            "overallWellbeingScore":
                overall_score,
        },


        "bands": {

            "heart":
                score_band(
                    heart_score
                ),

            "health":
                score_band(
                    health_score
                ),

            "wellness":
                score_band(
                    wellness_score
                ),

            "overall":
                score_band(
                    overall_score
                ),
        },


        "probabilities": {

            "heartOutcomeProbability":
                round(
                    prediction[
                        "heart"
                    ]["probability"],
                    4
                ),

            "healthOutcomeProbability":
                round(
                    prediction[
                        "health"
                    ]["probability"],
                    4
                ),

            "favorableWellnessProbability":
                round(
                    prediction[
                        "wellness"
                    ]["probability"],
                    4
                ),
        },


        "weights": {

            "heart":
                HEART_WEIGHT,

            "health":
                HEALTH_WEIGHT,

            "wellness":
                WELLNESS_WEIGHT,
        },
    }