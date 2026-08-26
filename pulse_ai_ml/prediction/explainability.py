from typing import Any, Dict, List


# ============================================================
# DIMENSION LABELS
# ============================================================

DIMENSION_LABELS = {

    "activity":
        "Physical Activity",

    "sleep":
        "Sleep",

    "recovery":
        "Recovery",

    "cardiovascular":
        "Cardiovascular",

    "body":
        "Body Composition",

    "oxygen":
        "Oxygenation",
}


# ============================================================
# SCORE LEVEL
# ============================================================

def score_level(
    score: float
) -> str:

    if score >= 90:

        return "excellent"

    if score >= 80:

        return "good"

    if score >= 70:

        return "moderate"

    if score >= 60:

        return "needs_attention"

    return "low"


# ============================================================
# DIMENSION EXPLANATION
# ============================================================

def explain_dimension(
    dimension: str,
    score: float
) -> Dict[str, Any]:

    label = DIMENSION_LABELS.get(
        dimension,
        dimension
    )

    level = score_level(
        score
    )


    if level == "excellent":

        evidence = (
            f"{label} is currently "
            f"one of the strongest "
            f"wellness dimensions."
        )


    elif level == "good":

        evidence = (
            f"{label} is in a generally "
            f"favorable range."
        )


    elif level == "moderate":

        evidence = (
            f"{label} is moderate and "
            f"could contribute to future "
            f"wellness improvement."
        )


    elif level == "needs_attention":

        evidence = (
            f"{label} is currently below "
            f"the stronger wellness dimensions "
            f"and deserves attention."
        )


    else:

        evidence = (
            f"{label} is currently a "
            f"significant area for improvement."
        )


    return {

        "dimension":
            dimension,

        "label":
            label,

        "score":
            round(
                score,
                2
            ),

        "level":
            level,

        "evidence":
            evidence,
    }


# ============================================================
# EXPLAIN WELLNESS
# ============================================================

def explain_wellness(
    wellness: Dict[str, Any]
) -> Dict[str, Any]:

    windows = wellness.get(
        "windows",
        {}
    )


    # ========================================================
    # Latest dimension scores
    # ========================================================

    latest = windows.get(
        "7d",
        {}
    )


    dimensions = latest.get(
        "dimensions",
        {}
    )


    explanations = []


    for (
        dimension,
        score
    ) in dimensions.items():

        explanations.append(

            explain_dimension(
                dimension,
                score
            )

        )


    # ========================================================
    # Sort strongest → weakest
    # ========================================================

    strongest = sorted(

        explanations,

        key=lambda item:
            item["score"],

        reverse=True
    )


    weakest = sorted(

        explanations,

        key=lambda item:
            item["score"]
    )


    # ========================================================
    # Positive factors
    # ========================================================

    positive_factors = [

        item

        for item in strongest

        if item["score"] >= 85
    ]


    # ========================================================
    # Attention factors
    # ========================================================

    attention_factors = [

        item

        for item in weakest

        if item["score"] < 80
    ]


    # ========================================================
    # Signals
    # ========================================================

    signals = wellness.get(
        "signals",
        []
    )


    improving = [

        signal

        for signal in signals

        if signal.get(
            "direction"
        ) == "improving"
    ]


    declining = [

        signal

        for signal in signals

        if signal.get(
            "direction"
        ) == "declining"
    ]


    # ========================================================
    # Trend interpretation
    # ========================================================

    status = wellness.get(
        "status",
        "unknown"
    )


    if status == "improving":

        trend_explanation = (
            "Recent wellness indicators "
            "are improving compared with "
            "the longer-term pattern."
        )


    elif status == "declining":

        trend_explanation = (
            "Recent wellness indicators "
            "are weaker than the longer-term "
            "pattern and should be monitored."
        )


    elif status == "stable":

        trend_explanation = (
            "Recent wellness indicators "
            "are broadly stable relative "
            "to the longer-term pattern."
        )


    else:

        trend_explanation = (
            "There is not enough information "
            "to determine a reliable trend."
        )


    # ========================================================
    # Generate attention summary
    # ========================================================

    if attention_factors:

        attention_summary = (
            "The main area requiring attention "
            "is "
            +
            ", ".join(
                item["label"]
                for item in attention_factors[:3]
            )
            +
            "."
        )

    else:

        attention_summary = (
            "No major low-scoring wellness "
            "dimension was detected."
        )


    # ========================================================
    # Generate positive summary
    # ========================================================

    if positive_factors:

        positive_summary = (
            "The strongest current wellness "
            "areas are "
            +
            ", ".join(
                item["label"]
                for item in positive_factors[:3]
            )
            +
            "."
        )

    else:

        positive_summary = (
            "There are currently no strongly "
            "positive wellness dimensions."
        )


    # ========================================================
    # Return evidence
    # ========================================================

    return {

        "overallScore":
            wellness.get(
                "personalWellnessScore"
            ),

        "baselineScore":
            wellness.get(
                "baselineScore"
            ),

        "longitudinalScore":
            wellness.get(
                "longitudinalScore"
            ),

        "status":
            status,

        "trendExplanation":
            trend_explanation,

        "positiveFactors":
            positive_factors,

        "attentionFactors":
            attention_factors,

        "improvingSignals":
            improving,

        "decliningSignals":
            declining,

        "positiveSummary":
            positive_summary,

        "attentionSummary":
            attention_summary,

        "dataQuality":
            wellness.get(
                "dataQuality"
            ),
    }