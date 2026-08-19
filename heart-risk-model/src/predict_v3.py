from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import joblib
import pandas as pd


from .config import (
    MODEL_DIR,
    FEATURES,
)


# ============================================================
# MODEL PATH
# ============================================================

MODEL_PATH = (
    MODEL_DIR /
    "heart_risk_model_v3_calibrated.joblib"
)

METADATA_PATH = (
    MODEL_DIR /
    "heart_risk_model_v3_metadata.json"
)


# ============================================================
# MODEL LOADING
# ============================================================

_MODEL = None
_METADATA = None


def load_model():

    global _MODEL

    if _MODEL is None:

        if not MODEL_PATH.exists():

            raise FileNotFoundError(
                f"Model not found:\n"
                f"{MODEL_PATH}"
            )

        _MODEL = joblib.load(
            MODEL_PATH
        )

    return _MODEL


def load_metadata():

    global _METADATA

    if _METADATA is None:

        if METADATA_PATH.exists():

            with open(
                METADATA_PATH,
                "r",
                encoding="utf-8",
            ) as file:

                _METADATA = json.load(
                    file
                )

        else:

            _METADATA = {
                "model_version":
                    "heart-risk-v3",

                "threshold":
                    0.175,
            }

    return _METADATA


# ============================================================
# INPUT VALIDATION
# ============================================================

def validate_input(
    user_data: dict[str, Any]
):

    missing = [
        feature
        for feature in FEATURES
        if feature not in user_data
    ]

    if missing:

        raise ValueError(
            "Missing required features: "
            + ", ".join(missing)
        )

    # Only use expected features
    cleaned = {
        feature:
            user_data.get(feature)
        for feature in FEATURES
    }

    return cleaned


# ============================================================
# PREDICTION
# ============================================================

def predict_heart_risk(
    user_data: dict[str, Any]
):

    model = load_model()

    metadata = load_metadata()

    cleaned = validate_input(
        user_data
    )

    X = pd.DataFrame(
        [cleaned]
    )

    probability = float(
        model.predict_proba(
            X
        )[0, 1]
    )

    threshold = float(
        metadata.get(
            "threshold",
            0.175,
        )
    )

    classification = (
        probability >= threshold
    )

    return {
        "model_version":
            metadata.get(
                "model_version",
                "heart-risk-v3",
            ),

        "risk_probability":
            round(
                probability,
                6,
            ),

        "risk_percentage":
            round(
                probability * 100,
                2,
            ),

        "risk_horizon":
            "10-year",

        "classification_threshold":
            threshold,

        "above_model_threshold":
            bool(
                classification
            ),

        "input_features":
            cleaned,
    }


# ============================================================
# BATCH PREDICTION
# ============================================================

def predict_dataframe(
    df: pd.DataFrame
):

    model = load_model()

    missing = [
        feature
        for feature in FEATURES
        if feature not in df.columns
    ]

    if missing:

        raise ValueError(
            "Missing required columns: "
            + ", ".join(missing)
        )

    probabilities = (
        model.predict_proba(
            df[FEATURES]
        )[:, 1]
    )

    metadata = load_metadata()

    threshold = float(
        metadata.get(
            "threshold",
            0.175,
        )
    )

    result = df.copy()

    result[
        "risk_probability"
    ] = probabilities

    result[
        "risk_percentage"
    ] = probabilities * 100

    result[
        "above_model_threshold"
    ] = (
        probabilities >= threshold
    )

    return result


# ============================================================
# TEST
# ============================================================

def main():

    print("=" * 75)
    print("HEART RISK V3 - INFERENCE TEST")
    print("=" * 75)

    example_user = {
        "male": 1,
        "age": 55,
        "education": 2,
        "currentSmoker": 0,
        "cigsPerDay": 0,
        "BPMeds": 0,
        "prevalentStroke": 0,
        "prevalentHyp": 1,
        "diabetes": 0,
        "totChol": 220,
        "sysBP": 145,
        "diaBP": 90,
        "BMI": 27.1,
        "heartRate": 75,
        "glucose": 90,
    }

    result = predict_heart_risk(
        example_user
    )

    print()

    print(
        json.dumps(
            result,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()