from typing import Any, Dict, List

from .predictor import get_predictor

from .explainability import (
    explain_wellness,
)

from .recommendation_engine import (
    generate_recommendations,
)

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
    # 1. ML PREDICTION
    # ========================================================

    predictor = get_predictor()

    ml_result = predictor.predict(
        profile
    )


    # ========================================================
    # 2. ML BASELINE SCORES
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
    # 3. NORMALIZE HEALTH RECORDS
    # ========================================================

    normalized_records = (
        adapt_health_records(
            health_records
        )
    )


    # ========================================================
    # 4. LONGITUDINAL WELLNESS ANALYSIS
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
    # 5. EXPLAINABILITY / EVIDENCE
    # ========================================================

    explanation = explain_wellness(
        wellness
    )


    # ========================================================
    # 6. PERSONALIZED RECOMMENDATIONS
    # ========================================================

    recommendations = (
        generate_recommendations(

            wellness,

            explanation,
        )
    )


    # ========================================================
    # 7. OVERALL WELLBEING SCORE
    # ========================================================

    overall_wellbeing = (
        calculate_overall_score(

            heart_score,

            health_score,

            personal_wellness,
        )
    )


    # ========================================================
    # 8. FINAL RESULT
    # ========================================================

    return {

        # ----------------------------------------------------
        # SCORES
        # ----------------------------------------------------

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


        # ----------------------------------------------------
        # SCORE BANDS
        # ----------------------------------------------------

        "bands":
            score_result[
                "bands"
            ],


        # ----------------------------------------------------
        # MODEL PROBABILITIES
        # ----------------------------------------------------

        "modelProbabilities":
            score_result[
                "probabilities"
            ],


        # ----------------------------------------------------
        # LONGITUDINAL WELLNESS
        # ----------------------------------------------------

        "wellness":
            wellness,


        # ----------------------------------------------------
        # EXPLAINABILITY
        # ----------------------------------------------------

        "explanation":
            explanation,


        # ----------------------------------------------------
        # PERSONALIZED RECOMMENDATIONS
        # ----------------------------------------------------

        "recommendations":
            recommendations,


        # ----------------------------------------------------
        # DATA QUALITY
        # ----------------------------------------------------

        "dataQuality":
            wellness[
                "dataQuality"
            ],


        # ----------------------------------------------------
        # MODEL INFORMATION
        # ----------------------------------------------------

        "modelVersion":
            "v2-deployment",


        # ----------------------------------------------------
        # BLOOD PRESSURE STATUS
        # ----------------------------------------------------

        "bloodPressureUsed":
            False,


        # ----------------------------------------------------
        # RECORD COUNT
        # ----------------------------------------------------

        "recordsAnalyzed":
            len(
                normalized_records
            ),
    }