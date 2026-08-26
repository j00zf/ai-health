from typing import Any, Dict, List


# ============================================================
# AI INTERPRETER
# ============================================================

class PulseAIInterpreter:
    """
    Generates a grounded natural-language interpretation
    from the structured Pulse AI analysis context.

    This class does NOT calculate health scores.

    It only interprets values already produced by the
    ML/scoring/forecasting pipeline.
    """


    # ========================================================
    # CONSTRUCTOR
    # ========================================================

    def __init__(
        self,
        provider: str = "deterministic",
    ):

        self.provider = provider


    # ========================================================
    # INTERPRET
    # ========================================================

    def interpret(
        self,
        context: Dict[str, Any],
    ) -> Dict[str, Any]:

        # ----------------------------------------------------
        # Extract source sections
        # ----------------------------------------------------

        scores = context.get(
            "scores",
            {},
        )

        wellness = context.get(
            "wellness",
            {},
        )

        explanation = context.get(
            "explanation",
            {},
        )

        recommendations = context.get(
            "recommendations",
            {},
        )

        data_quality = context.get(
            "dataQuality",
            {},
        )

        forecast = context.get(
            "forecast",
            {},
        )


        # ====================================================
        # SCORE VALUES
        # ====================================================

        heart_score = scores.get(
            "heartHealthScore"
        )

        health_score = scores.get(
            "healthScore"
        )

        personal_score = scores.get(
            "personalWellnessScore"
        )

        overall_score = scores.get(
            "overallWellbeingScore"
        )


        # ====================================================
        # WELLNESS STATUS
        # ====================================================

        status = wellness.get(
            "status",
            "unknown",
        )


        # ====================================================
        # MAIN OPPORTUNITY
        # ====================================================

        main_opportunity = (
            recommendations.get(
                "mainOpportunity"
            )
        )


        # ====================================================
        # SUMMARY
        # ====================================================

        summary = self._build_summary(

            heart_score,

            health_score,

            personal_score,

            overall_score,

            status,
        )


        # ====================================================
        # STRENGTHS
        # ====================================================

        strengths = (
            self._build_strengths(
                explanation
            )
        )


        # ====================================================
        # OPPORTUNITIES
        # ====================================================

        opportunities = (
            self._build_opportunities(

                explanation,

                main_opportunity,
            )
        )


        # ====================================================
        # ACTIONS
        # ====================================================

        actions = (
            self._build_actions(
                recommendations
            )
        )


        # ====================================================
        # FORECAST
        # ====================================================

        forecast_interpretation = (
            self._build_forecast_interpretation(
                forecast
            )
        )


        # ====================================================
        # NARRATIVE
        # ====================================================

        narrative = self._build_narrative(

            summary,

            strengths,

            opportunities,

            actions,

            forecast_interpretation,
        )


        # ====================================================
        # FINAL RESULT
        # ====================================================

        return {

            "summary":
                summary,

            "strengths":
                strengths,

            "opportunities":
                opportunities,

            "actions":
                actions,

            "forecast":
                forecast_interpretation,

            "narrative":
                narrative,

            "scores":
                scores,

            "dataQuality":
                data_quality,

            "provider":
                self.provider,

            "grounded":
                True,

            "medicalDiagnosis":
                False,
        }


    # ========================================================
    # SUMMARY
    # ========================================================

    def _build_summary(

        self,

        heart_score: Any,

        health_score: Any,

        personal_score: Any,

        overall_score: Any,

        status: str,

    ) -> str:

        return (

            f"Your current modeled overall wellbeing "
            f"score is {overall_score:.1f}. "

            f"Your modeled heart-health score is "
            f"{heart_score:.1f}, while your modeled "
            f"general health score is "
            f"{health_score:.1f}. "

            f"Your personal wellness score is "
            f"{personal_score:.1f}, and your recent "
            f"wellness pattern is {status}."

        )


    # ========================================================
    # STRENGTHS
    # ========================================================

    def _build_strengths(
        self,
        explanation: Dict[str, Any],
    ) -> List[str]:

        factors = explanation.get(
            "positiveFactors",
            [],
        )

        strengths = []


        for factor in factors[:3]:

            label = factor.get(
                "label",
                factor.get(
                    "dimension",
                    "Unknown",
                ),
            )

            score = factor.get(
                "score"
            )


            if score is not None:

                strengths.append(

                    f"{label} is currently "
                    f"strong with a modeled "
                    f"score of {score:.1f}."
                )

            else:

                strengths.append(

                    f"{label} is currently "
                    f"one of the stronger "
                    f"wellness areas."
                )


        return strengths


    # ========================================================
    # OPPORTUNITIES
    # ========================================================

    def _build_opportunities(

        self,

        explanation: Dict[str, Any],

        main_opportunity: Any,

    ) -> List[str]:

        opportunities = []


        # ----------------------------------------------------
        # Main opportunity
        # ----------------------------------------------------

        if main_opportunity:

            label = main_opportunity.get(
                "label",
                main_opportunity.get(
                    "dimension",
                    "Unknown",
                ),
            )

            score = main_opportunity.get(
                "score"
            )


            if score is not None:

                opportunities.append(

                    f"{label} is currently "
                    f"the main opportunity area "
                    f"with a score of {score:.1f}."
                )


        # ----------------------------------------------------
        # Attention factors
        # ----------------------------------------------------

        attention_factors = explanation.get(
            "attentionFactors",
            [],
        )


        for factor in attention_factors[:2]:

            label = factor.get(
                "label",
                factor.get(
                    "dimension",
                    "Unknown",
                ),
            )

            score = factor.get(
                "score"
            )


            if score is not None:

                text = (

                    f"{label} currently has "
                    f"a modeled score of "
                    f"{score:.1f} and may "
                    f"benefit from attention."
                )

            else:

                text = (

                    f"{label} may benefit "
                    f"from additional attention."
                )


            # Prevent duplicate opportunity
            if not any(
                label in existing
                for existing in opportunities
            ):

                opportunities.append(
                    text
                )


        return opportunities


    # ========================================================
    # ACTIONS
    # ========================================================

    def _build_actions(

        self,

        recommendations: Dict[str, Any],

    ) -> List[str]:

        actions = []


        items = recommendations.get(
            "recommendations",
            [],
        )


        for recommendation in items[:3]:

            action = recommendation.get(
                "action"
            )


            if action:

                actions.append(
                    action
                )


        return actions


    # ========================================================
    # FORECAST INTERPRETATION
    # ========================================================

    def _build_forecast_interpretation(

        self,

        forecast: Dict[str, Any],

    ) -> str:

        if not forecast:

            return (
                "No wellbeing forecast is currently available."
            )


        current = forecast.get(
            "current"
        )

        forecast_7d = forecast.get(
            "forecast7d"
        )

        forecast_14d = forecast.get(
            "forecast14d"
        )

        forecast_30d = forecast.get(
            "forecast30d"
        )

        trajectory = forecast.get(
            "trajectory",
            "unknown",
        )

        confidence = forecast.get(
            "confidence",
            0,
        )


        # ----------------------------------------------------
        # Handle incomplete forecast
        # ----------------------------------------------------

        if (
            current is None
            or forecast_7d is None
            or forecast_14d is None
            or forecast_30d is None
        ):

            return (
                "A complete wellbeing forecast "
                "is not currently available."
            )


        trajectory_text = (
            str(trajectory)
            .replace(
                "_",
                " ",
            )
        )


        return (

            f"Based on the current longitudinal pattern, "
            f"the wellbeing trajectory is projected as "
            f"{trajectory_text}. "

            f"The current forecast score is "
            f"{current:.1f}. "

            f"The projected 7-day score is "
            f"{forecast_7d:.1f}, the projected 14-day "
            f"score is {forecast_14d:.1f}, and the "
            f"projected 30-day score is "
            f"{forecast_30d:.1f}. "

            f"The forecast confidence is approximately "
            f"{confidence:.0f}%."

        )


    # ========================================================
    # NARRATIVE
    # ========================================================

    def _build_narrative(

        self,

        summary: str,

        strengths: List[str],

        opportunities: List[str],

        actions: List[str],

        forecast: str,

    ) -> str:

        parts = []


        # ----------------------------------------------------
        # Summary
        # ----------------------------------------------------

        parts.append(
            summary
        )


        # ----------------------------------------------------
        # Strengths
        # ----------------------------------------------------

        if strengths:

            strengths_text = (
                "; ".join(
                    strengths
                )
            )

            parts.append(

                "Your strongest current areas are "
                + strengths_text

            )


        # ----------------------------------------------------
        # Opportunities
        # ----------------------------------------------------

        if opportunities:

            opportunities_text = (
                "; ".join(
                    opportunities
                )
            )

            parts.append(

                "The main opportunities identified "
                "by the analysis are "
                + opportunities_text

            )


        # ----------------------------------------------------
        # Actions
        # ----------------------------------------------------

        if actions:

            actions_text = (
                "; ".join(
                    actions
                )
            )

            parts.append(

                "Based on these signals, the most "
                "relevant actions are "
                + actions_text

            )


        # ----------------------------------------------------
        # Forecast
        # ----------------------------------------------------

        if forecast:

            parts.append(
                forecast
            )


        # ----------------------------------------------------
        # Safety
        # ----------------------------------------------------

        parts.append(

            "These results are model-based wellness "
            "insights rather than a medical diagnosis. "
            "The forecast represents a projection from "
            "the available longitudinal pattern and "
            "does not guarantee a future outcome. "
            "The interpretation does not replace "
            "professional medical advice."

        )


        return "\n\n".join(
            parts
        )


# ============================================================
# FACTORY
# ============================================================

def get_interpreter() -> PulseAIInterpreter:

    return PulseAIInterpreter(
        provider="deterministic"
    )