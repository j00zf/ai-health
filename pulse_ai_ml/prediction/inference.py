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
# MAIN USER ANALYSIS
# ============================================================

def analyze_user(
    profile: Dict[str, Any],
    health_records: List[Dict[str, Any]],
) -> Dict[str, Any]:

    # ========================================================
    # ML INPUT
    # ========================================================

    predictor = get_predictor()


    ml_result = predictor.predict(
        profile
    )


    # ========================================================
    # BASELINE SCORES
    # ========================================================

    scores = build_score_response(
        ml_result
    )


    baseline_wellness = (
        scores["scores"]
        ["wellnessBaselineScore"]
    )


    # ========================================================
    # ADAPT PULSE RECORDS
    # ========================================================

    normalized_records = (
        adapt_health_records(
            health_records
        )
    )


    # ========================================================
    # PERSONAL WELLNESS
    # ========================================================

    wellness = analyze_wellness(

        normalized_records,

        baseline_wellness,
    )


    personal_wellness = (
        wellness[
            "personalWellnessScore"
        ]
    )


    # ========================================================
    # OVERALL WELLBEING
    # ========================================================
    #
    # Heart and Health remain population-model scores.
    #
    # Wellness becomes personalized using longitudinal data.
    #
    # ========================================================

    heart_score = (
        scores["scores"]
        ["heartHealthScore"]
    )


    health_score = (
        scores["scores"]
        ["healthScore"]
    )


    overall = calculate_overall_score(

        heart_score,

        health_score,

        personal_wellness,
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
                baseline_wellness,

            "personalWellnessScore":
                personal_wellness,

            "overallWellbeingScore":
                overall,
        },


        "bands":
            scores["bands"],


        "modelProbabilities":
            scores["probabilities"],


        "personalWellness":
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