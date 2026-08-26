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

from .ai_context import (
    build_ai_context,
)

from .ai_interpreter import (
    get_interpreter,
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
    # 4. LONGITUDINAL WELLNESS
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
    # 5. EXPLAINABILITY
    # ========================================================

    explanation = explain_wellness(
        wellness
    )


    # ========================================================
    # 6. RECOMMENDATIONS
    # ========================================================

    recommendations = (
        generate_recommendations(

            wellness,

            explanation,
        )
    )


    # ========================================================
    # 7. OVERALL WELLBEING
    # ========================================================

    overall_wellbeing = (
        calculate_overall_score(

            heart_score,

            health_score,

            personal_wellness,
        )
    )


    # ========================================================
    # 8. BASE ANALYSIS OBJECT
    # ========================================================

    base_analysis = {

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

        "modelProbabilities":
            score_result[
                "probabilities"
            ],

        "wellness":
            wellness,

        "explanation":
            explanation,

        "recommendations":
            recommendations,

        "dataQuality":
            wellness[
                "dataQuality"
            ],

        "modelVersion":
            "v2-deployment",

        "bloodPressureUsed":
            False,
    }


    # ========================================================
    # 9. AI CONTEXT
    # ========================================================

    ai_context = build_ai_context(
        base_analysis
    )


    # ========================================================
    # 10. AI INTERPRETATION
    # ========================================================

    interpreter = get_interpreter()

    ai_interpretation = (
        interpreter.interpret(
            ai_context
        )
    )


    # ========================================================
    # 11. FINAL RESULT
    # ========================================================

    return {

        "scores":
            base_analysis[
                "scores"
            ],

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

        "explanation":
            explanation,

        "recommendations":
            recommendations,

        "aiContext":
            ai_context,

        "aiInterpretation":
            ai_interpretation,

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