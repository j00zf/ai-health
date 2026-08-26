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
    ML/scoring pipeline.
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

        scores = context.get(
            "scores",
            {},
        )

        wellness = context.get(
            "wellness",
            {},
        )

        dimensions = context.get(
            "currentDimensions",
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


        # ====================================================
        # Scores
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
        # Wellness status
        # ====================================================

        status = wellness.get(
            "status",
            "unknown",
        )


        # ====================================================
        # Main opportunity
        # ====================================================

        main_opportunity = (
            recommendations.get(
                "mainOpportunity"
            )
        )


        # ====================================================
        # Generate summary
        # ====================================================

        summary = self._build_summary(

            heart_score,

            health_score,

            personal_score,

            overall_score,

            status,
        )


        # ====================================================
        # Generate strengths
        # ====================================================

        strengths = (
            self._build_strengths(
                explanation
            )
        )


        # ====================================================
        # Generate opportunities
        # ====================================================

        opportunities = (
            self._build_opportunities(
                explanation,
                main_opportunity,
            )
        )


        # ====================================================
        # Generate actions
        # ====================================================

        actions = (
            self._build_actions(
                recommendations
            )
        )


        # ====================================================
        # Build final interpretation
        # ====================================================

        narrative = self._build_narrative(

            summary,

            strengths,

            opportunities,

            actions,

            status,
        )


        # ====================================================
        # Return
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
            f"general health score is {health_score:.1f}. "

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

            reason = main_opportunity.get(
                "reason"
            )


            if score is not None:

                opportunities.append(

                    f"{label} is currently "
                    f"the main opportunity area "
                    f"with a score of {score:.1f}."
                )

            elif reason:

                opportunities.append(
                    reason
                )


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


            if text not in opportunities:

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
    # NARRATIVE
    # ========================================================

    def _build_narrative(

        self,

        summary: str,

        strengths: List[str],

        opportunities: List[str],

        actions: List[str],

        status: str,

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

            parts.append(
                "Your strongest current areas are "
                + " ".join(
                    strengths
                )
            )


        # ----------------------------------------------------
        # Opportunities
        # ----------------------------------------------------

        if opportunities:

            parts.append(
                "The main opportunities identified "
                "by the analysis are "
                + " ".join(
                    opportunities
                )
            )


        # ----------------------------------------------------
        # Actions
        # ----------------------------------------------------

        if actions:

            parts.append(
                "Based on these signals, the most "
                "relevant actions are "
                + " ".join(
                    actions
                )
            )


        # ----------------------------------------------------
        # Final safety statement
        # ----------------------------------------------------

        parts.append(

            "These results are model-based wellness "
            "insights rather than a medical diagnosis. "
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