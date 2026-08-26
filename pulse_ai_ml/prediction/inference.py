from typing import Any, Dict, List

from .predictor import get_predictor

from .score_engine import (
    build_score_response,
    calculate_overall_score,
)

from .pulse_adapter import (
    adapt_health_records,
)

from .wellness_engine import (
    analyze_wellness,
)


# ============================================================
# ANALYZE USER
# ============================================================

def analyze_user(
    profile: Dict[str, Any],
    health_records: List[Dict[str, Any]],
) -> Dict[str, Any]:

    # ========================================================
    # ML PREDICTION
    # ========================================================

    predictor = get_predictor()

    ml_result = predictor.predict(
        profile
    )


    # ========================================================
    # ML BASELINE SCORES
    # ========================================================

    score_result = build_score_response(
        ml_result
    )


    heart_score = (
        score_result["scores"]
        ["heartHealthScore"]
    )


    health_score = (
        score_result["scores"]
        ["healthScore"]
    )


    wellness_baseline = (
        score_result["scores"]
        ["wellnessBaselineScore"]
    )


    # ========================================================
    # NORMALIZE HEALTH RECORDS
    # ========================================================

    normalized_records = (
        adapt_health_records(
            health_records
        )
    )


    # ========================================================
    # LONGITUDINAL WELLNESS
    # ========================================================

    wellness = analyze_wellness(

        normalized_records,

        wellness_baseline,
    )


    personal_wellness = (
        wellness[
            "personalWellnessScore"
        ]
    )


    # ========================================================
    # OVERALL WELLBEING
    # ========================================================

    overall_wellbeing = (
        calculate_overall_score(

            heart_score,

            health_score,

            personal_wellness,
        )
    )


    # ========================================================
    # FINAL RESULT
    # ========================================================

    return {

        "scores": {

            "heartHealthScore":
                heart_score,

            "healthScore":
                health_score,

            "wellnessBaselineScore":
                wellness_baseline,

            "personalWellnessScore":
                personal_wellness,

            "overallWellbeingScore":
                overall_wellbeing,
        },


        "bands":
            score_result[
                "bands"
            ],


        "modelProbabilities":
            score_result[
                "probabilities"
            ],


        "wellness":
            wellness,


        "dataQuality":
            wellness[
                "dataQuality"
            ],


        "modelVersion":
            "v2-deployment",


        "bloodPressureUsed":
            False,


        "recordsAnalyzed":
            len(
                normalized_records
            ),
    }