from typing import Any, Dict, List


# ============================================================
# PRIORITY ORDER
# ============================================================

PRIORITY_ORDER = {
    "high": 3,
    "medium": 2,
    "low": 1,
}


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
# CREATE RECOMMENDATION
# ============================================================

def create_recommendation(
    dimension: str,
    priority: str,
    reason: str,
    action: str,
    goal: str,
) -> Dict[str, Any]:

    return {

        "dimension":
            dimension,

        "label":
            DIMENSION_LABELS.get(
                dimension,
                dimension,
            ),

        "priority":
            priority,

        "reason":
            reason,

        "action":
            action,

        "goal":
            goal,
    }


# ============================================================
# ACTIVITY RECOMMENDATION
# ============================================================

def activity_recommendation(
    score: float,
    improving: bool,
) -> Dict[str, Any]:

    if score < 60:

        return create_recommendation(

            "activity",

            "high",

            (
                "Physical activity is currently "
                "one of the weaker wellness dimensions."
            ),

            (
                "Gradually increase daily movement "
                "and aim for consistent activity "
                "across the week."
            ),

            (
                "Build a consistent physical activity routine."
            ),
        )


    if score < 80:

        if improving:

            return create_recommendation(

                "activity",

                "low",

                (
                    "Physical activity is moderate "
                    "but the recent trend is improving."
                ),

                (
                    "Maintain the current upward trend "
                    "and focus on consistency."
                ),

                (
                    "Continue improving activity consistency."
                ),
            )


        return create_recommendation(

            "activity",

            "medium",

            (
                "Physical activity is currently "
                "below the stronger wellness dimensions."
            ),

            (
                "Gradually increase daily movement "
                "while maintaining consistency."
            ),

            (
                "Improve weekly activity consistency."
            ),
        )


    return create_recommendation(

        "activity",

        "low",

        (
            "Physical activity is currently "
            "in a favorable range."
        ),

        (
            "Maintain the current activity pattern."
        ),

        (
            "Maintain physical activity."
        ),
    )


# ============================================================
# SLEEP RECOMMENDATION
# ============================================================

def sleep_recommendation(
    score: float,
    improving: bool,
) -> Dict[str, Any]:

    if score < 60:

        return create_recommendation(

            "sleep",

            "high",

            (
                "Sleep is currently one of the "
                "lower wellness dimensions."
            ),

            (
                "Prioritize a consistent sleep schedule "
                "and adequate nightly sleep."
            ),

            (
                "Improve sleep consistency and duration."
            ),
        )


    if score < 80:

        return create_recommendation(

            "sleep",

            "medium",

            (
                "Sleep is moderate and may have "
                "room for improvement."
            ),

            (
                "Maintain a consistent sleep schedule "
                "and monitor sleep duration."
            ),

            (
                "Improve sleep quality and consistency."
            ),
        )


    return create_recommendation(

        "sleep",

        "low",

        (
            "Sleep is currently one of the "
            "stronger wellness dimensions."
        ),

        (
            "Maintain the current sleep routine."
        ),

        (
            "Maintain healthy sleep habits."
        ),
    )


# ============================================================
# RECOVERY RECOMMENDATION
# ============================================================

def recovery_recommendation(
    score: float,
) -> Dict[str, Any]:

    if score < 70:

        return create_recommendation(

            "recovery",

            "high",

            (
                "Recovery indicators are currently "
                "below the stronger wellness dimensions."
            ),

            (
                "Prioritize adequate rest, sleep "
                "and recovery between periods "
                "of activity."
            ),

            (
                "Improve recovery and reduce excessive load."
            ),
        )


    if score < 85:

        return create_recommendation(

            "recovery",

            "medium",

            (
                "Recovery is moderate."
            ),

            (
                "Maintain adequate rest and monitor "
                "recovery alongside activity."
            ),

            (
                "Maintain a balanced activity-recovery pattern."
            ),
        )


    return create_recommendation(

        "recovery",

        "low",

        (
            "Recovery indicators are currently favorable."
        ),

        (
            "Maintain the current recovery routine."
        ),

        (
            "Maintain recovery habits."
        ),
    )


# ============================================================
# GENERAL DIMENSION RECOMMENDATION
# ============================================================

def general_dimension_recommendation(
    dimension: str,
    score: float,
) -> Dict[str, Any]:

    label = DIMENSION_LABELS.get(
        dimension,
        dimension,
    )


    if score < 60:

        priority = "high"

    elif score < 80:

        priority = "medium"

    else:

        priority = "low"


    # --------------------------------------------------------
    # Cardiovascular
    # --------------------------------------------------------

    if dimension == "cardiovascular":

        action = (
            "Maintain regular physical activity, "
            "adequate recovery and healthy daily habits."
        )

        goal = (
            "Support cardiovascular wellness."
        )


    # --------------------------------------------------------
    # Body
    # --------------------------------------------------------

    elif dimension == "body":

        action = (
            "Maintain balanced nutrition, regular "
            "movement and consistent daily habits."
        )

        goal = (
            "Maintain healthy body composition."
        )


    # --------------------------------------------------------
    # Oxygen
    # --------------------------------------------------------

    elif dimension == "oxygen":

        action = (
            "Continue monitoring your usual health "
            "patterns and maintain healthy daily habits."
        )

        goal = (
            "Maintain oxygenation-related wellness indicators."
        )


    # --------------------------------------------------------
    # Generic
    # --------------------------------------------------------

    else:

        action = (
            f"Continue monitoring {label.lower()} "
            "and maintain consistent healthy habits."
        )

        goal = (
            f"Maintain {label.lower()}."
        )


    return create_recommendation(

        dimension,

        priority,

        (
            f"{label} has a wellness score "
            f"of {score:.1f}."
        ),

        action,

        goal,
    )


# ============================================================
# MAIN RECOMMENDATION ENGINE
# ============================================================

def generate_recommendations(
    wellness: Dict[str, Any],
    explanation: Dict[str, Any],
) -> Dict[str, Any]:

    recommendations: List[
        Dict[str, Any]
    ] = []


    # ========================================================
    # GET 7-DAY DIMENSIONS
    # ========================================================

    windows = wellness.get(
        "windows",
        {},
    )


    latest = windows.get(
        "7d",
        {},
    )


    dimensions = latest.get(
        "dimensions",
        {},
    )


    # ========================================================
    # GET TREND SIGNALS
    # ========================================================

    signals = wellness.get(
        "signals",
        [],
    )


    improving_dimensions = {

        signal.get("dimension")

        for signal in signals

        if signal.get(
            "direction"
        ) == "improving"
    }


    declining_dimensions = {

        signal.get("dimension")

        for signal in signals

        if signal.get(
            "direction"
        ) == "declining"
    }


    # ========================================================
    # GENERATE ALL DIMENSION RECOMMENDATIONS
    # ========================================================

    for dimension, score in dimensions.items():

        # ----------------------------------------------------
        # Activity
        # ----------------------------------------------------

        if dimension == "activity":

            recommendation = activity_recommendation(

                score,

                dimension
                in improving_dimensions,
            )


        # ----------------------------------------------------
        # Sleep
        # ----------------------------------------------------

        elif dimension == "sleep":

            recommendation = sleep_recommendation(

                score,

                dimension
                in improving_dimensions,
            )


        # ----------------------------------------------------
        # Recovery
        # ----------------------------------------------------

        elif dimension == "recovery":

            recommendation = recovery_recommendation(
                score
            )


        # ----------------------------------------------------
        # Other dimensions
        # ----------------------------------------------------

        else:

            recommendation = (
                general_dimension_recommendation(

                    dimension,

                    score,
                )
            )


        # ----------------------------------------------------
        # Increase priority when declining
        # ----------------------------------------------------

        if dimension in declining_dimensions:

            if recommendation[
                "priority"
            ] == "low":

                recommendation[
                    "priority"
                ] = "medium"


            elif recommendation[
                "priority"
            ] == "medium":

                recommendation[
                    "priority"
                ] = "high"


            recommendation[
                "reason"
            ] += (
                " A recent declining trend "
                "has also been detected."
            )


        recommendations.append(
            recommendation
        )


    # ========================================================
    # REMOVE DUPLICATE GOALS
    # ========================================================

    seen_goals = set()

    unique_recommendations = []


    for recommendation in recommendations:

        goal = recommendation[
            "goal"
        ]


        if goal in seen_goals:

            continue


        seen_goals.add(
            goal
        )


        unique_recommendations.append(
            recommendation
        )


    recommendations = (
        unique_recommendations
    )


    # ========================================================
    # SEPARATE ACTIONABLE VS MAINTENANCE
    # ========================================================

    action_items = []

    maintenance_items = []


    for recommendation in recommendations:

        dimension = recommendation[
            "dimension"
        ]


        score = dimensions.get(
            dimension,
            100,
        )


        priority = recommendation[
            "priority"
        ]


        is_declining = (
            dimension
            in
            declining_dimensions
        )


        # ----------------------------------------------------
        # Actionable if:
        #
        # 1. Score < 85
        # OR
        # 2. Declining
        # OR
        # 3. Medium/high priority
        # ----------------------------------------------------

        if (

            score < 85

            or

            is_declining

            or

            priority in (
                "medium",
                "high",
            )

        ):

            action_items.append(
                recommendation
            )

        else:

            maintenance_items.append(
                recommendation
            )


    # ========================================================
    # SORT ACTIONABLE ITEMS
    # ========================================================

    action_items.sort(

        key=lambda item: (

            -PRIORITY_ORDER.get(
                item["priority"],
                0,
            ),

            dimensions.get(
                item["dimension"],
                100,
            ),
        )
    )


    # ========================================================
    # SORT MAINTENANCE ITEMS
    # ========================================================

    maintenance_items.sort(

        key=lambda item:

            dimensions.get(
                item["dimension"],
                100,
            ),

        reverse=True,
    )


    # ========================================================
    # LIMIT PRIMARY RECOMMENDATIONS
    #
    # Maximum of 3 actionable recommendations.
    # ========================================================

    primary_recommendations = (
        action_items[:3]
    )


    # ========================================================
    # OVERALL WELLNESS SCORE
    # ========================================================

    personal_score = wellness.get(
        "personalWellnessScore"
    )


    status = wellness.get(
        "status",
        "unknown",
    )


    # ========================================================
    # OVERALL MESSAGE
    # ========================================================

    if (
        personal_score is not None
        and personal_score >= 90
    ):

        overall_message = (
            "Your current wellness profile is "
            "strong. Focus on maintaining your "
            "strongest habits while improving "
            "the areas with the greatest "
            "opportunity."
        )


    elif (
        personal_score is not None
        and personal_score >= 80
    ):

        overall_message = (
            "Your overall wellness profile is "
            "generally favorable. Focus on the "
            "areas with the greatest opportunity "
            "for improvement."
        )


    elif (
        personal_score is not None
        and personal_score >= 70
    ):

        overall_message = (
            "Your wellness profile has several "
            "areas that could benefit from "
            "consistent improvement."
        )


    else:

        overall_message = (
            "Several wellness indicators may "
            "benefit from gradual improvement "
            "and continued monitoring."
        )


    # ========================================================
    # TREND MESSAGE
    # ========================================================

    if status == "improving":

        trend_message = (
            "Your recent wellness pattern is improving."
        )


    elif status == "declining":

        trend_message = (
            "Some recent wellness indicators "
            "are declining and should be monitored."
        )


    elif status == "stable":

        trend_message = (
            "Your recent wellness pattern "
            "is broadly stable."
        )


    else:

        trend_message = (
            "There is not enough information "
            "to determine a reliable wellness trend."
        )


    # ========================================================
    # MAIN OPPORTUNITY
    # ========================================================

    if primary_recommendations:

        main = primary_recommendations[0]


        main_opportunity = {

            "dimension":
                main["dimension"],

            "label":
                main["label"],

            "score":
                dimensions.get(
                    main["dimension"]
                ),

            "priority":
                main["priority"],

            "reason":
                main["reason"],

            "action":
                main["action"],

            "goal":
                main["goal"],
        }


    else:

        main_opportunity = None


    # ========================================================
    # RETURN
    # ========================================================

    return {

        # ----------------------------------------------------
        # Overall recommendation
        # ----------------------------------------------------

        "overallMessage":
            overall_message,


        # ----------------------------------------------------
        # Overall trend
        # ----------------------------------------------------

        "trendMessage":
            trend_message,


        # ----------------------------------------------------
        # Main opportunity
        # ----------------------------------------------------

        "mainOpportunity":
            main_opportunity,


        # ----------------------------------------------------
        # Maximum 3 actionable recommendations
        # ----------------------------------------------------

        "recommendations":
            primary_recommendations,


        # ----------------------------------------------------
        # Strong areas to maintain
        # ----------------------------------------------------

        "maintenance":
            maintenance_items,


        # ----------------------------------------------------
        # Counts
        # ----------------------------------------------------

        "recommendationCount":
            len(
                primary_recommendations
            ),

        "maintenanceCount":
            len(
                maintenance_items
            ),
    }