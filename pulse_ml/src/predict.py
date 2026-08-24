import os
import joblib
import numpy as np
import pandas as pd
import shap


MODEL_PATH = "../models/advanced/xgboost.pkl"

THRESHOLD = 0.34

FEATURES = [
    "age_years",
    "sex",
    "height",
    "weight",
    "bmi",
    "smoke",
    "alco",
    "active",
    "ap_hi",
    "ap_lo",
    "cholesterol",
]


def calculate_bmi(
    height_cm,
    weight_kg,
):

    if not height_cm or not weight_kg:
        return 0.0

    height_m = height_cm / 100.0

    if height_m <= 0:
        return 0.0

    return weight_kg / (
        height_m * height_m
    )


def load_model():

    model = joblib.load(
        MODEL_PATH
    )

    return model


def create_explainer(model):

    """
    SHAP explainer.

    This script is intended to run inside the
    .venv-shap environment using:

        XGBoost 2.1.4
        SHAP 0.49.1
    """

    return shap.TreeExplainer(
        model
    )


def predict_user(
    user_data,
):

    model = load_model()

    # =========================================================
    # BUILD FEATURE VECTOR
    # =========================================================

    row = {}

    for feature in FEATURES:

        row[feature] = user_data.get(
            feature,
            np.nan,
        )

    X = pd.DataFrame(
        [row],
        columns=FEATURES,
    )

    # =========================================================
    # MODEL PROBABILITY
    # =========================================================

    probability = float(
        model.predict_proba(
            X
        )[0][1]
    )

    # =========================================================
    # THRESHOLD CLASSIFICATION
    # =========================================================

    predicted_class = int(
        probability >= THRESHOLD
    )

    # =========================================================
    # HEALTH SCORE
    # =========================================================
    #
    # This is an application score derived from the
    # model probability. It is NOT a clinical score.
    #
    # Higher probability -> lower score.
    #

    score = round(
        (1.0 - probability) * 100
    )

    score = max(
        0,
        min(
            100,
            score,
        ),
    )

    # =========================================================
    # SHAP
    # =========================================================

    explainer = create_explainer(
        model
    )

    shap_values = (
        explainer.shap_values(
            X
        )
    )

    shap_values = np.asarray(
        shap_values
    )

    if shap_values.ndim == 3:

        shap_values = (
            shap_values[:, :, -1]
        )

    contributions = (
        shap_values[0]
    )

    # =========================================================
    # CONTRIBUTION TABLE
    # =========================================================

    explanation = []

    for feature, value, contribution in zip(
        FEATURES,
        X.iloc[0].values,
        contributions,
    ):

        explanation.append(
            {
                "feature": feature,
                "value": (
                    None
                    if pd.isna(value)
                    else float(value)
                ),
                "shap": float(
                    contribution
                ),
                "direction": (
                    "increases"
                    if contribution > 0
                    else "decreases"
                ),
            }
        )

    # Strongest contributors first

    explanation.sort(
        key=lambda x: abs(
            x["shap"]
        ),
        reverse=True,
    )

    # =========================================================
    # POSITIVE / NEGATIVE
    # =========================================================

    positive = [
        item
        for item in explanation
        if item["shap"] > 0
    ]

    negative = [
        item
        for item in explanation
        if item["shap"] < 0
    ]

    # =========================================================
    # TOP CONTRIBUTORS
    # =========================================================

    top_positive = positive[:5]

    top_negative = negative[:5]

    # =========================================================
    # CLASSIFICATION LABEL
    # =========================================================

    if probability < 0.20:

        classification = "low"

    elif probability < 0.34:

        classification = "lower"

    elif probability < 0.50:

        classification = "elevated"

    elif probability < 0.70:

        classification = "high"

    else:

        classification = "very_high"

    # =========================================================
    # RESULT
    # =========================================================

    return {
        "model": "pulse_ai_advanced_v1",

        "probability": round(
            probability,
            4,
        ),

        "score": score,

        "threshold": THRESHOLD,

        "classification":
            classification,

        "predicted_class":
            predicted_class,

        "top_positive":
            top_positive,

        "top_negative":
            top_negative,

        "all_contributions":
            explanation,
    }


# ============================================================================
# TEST
# ============================================================================

if __name__ == "__main__":

    print("=" * 80)
    print(
        "PULSE AI ADVANCED — INDIVIDUAL PREDICTION"
    )
    print("=" * 80)

    # Example only.
    #
    # Replace these values later with the user's
    # actual MongoDB/profile/clinical data.

    example_user = {

        "age_years": 45,

        "sex": 1,

        "height": 170,

        "weight": 75,

        "bmi": calculate_bmi(
            170,
            75,
        ),

        "smoke": 0,

        "alco": 0,

        "active": 1,

        "ap_hi": 130,

        "ap_lo": 80,

        "cholesterol": 1,
    }

    result = predict_user(
        example_user
    )

    print("\n")
    print("=" * 80)
    print(
        "RESULT"
    )
    print("=" * 80)

    print(
        f"\nProbability: "
        f"{result['probability']}"
    )

    print(
        f"Pulse AI Score: "
        f"{result['score']}/100"
    )

    print(
        f"Classification: "
        f"{result['classification']}"
    )

    print(
        f"Threshold: "
        f"{result['threshold']}"
    )

    print(
        "\nTop positive contributors:"
    )

    for item in result[
        "top_positive"
    ]:

        print(
            f"  {item['feature']}: "
            f"{item['value']} "
            f"(SHAP {item['shap']:.4f})"
        )

    print(
        "\nTop negative contributors:"
    )

    for item in result[
        "top_negative"
    ]:

        print(
            f"  {item['feature']}: "
            f"{item['value']} "
            f"(SHAP {item['shap']:.4f})"
        )