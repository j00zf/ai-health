from __future__ import annotations

import joblib
import pandas as pd

from .config import FEATURES, MODEL_DIR


EXAMPLE_USER = {
    "male": 1,
    "age": 27,
    "currentSmoker": 0,
    "cigsPerDay": 0,
    "BPMeds": 0,
    "prevalentStroke": 0,
    "prevalentHyp": 0,
    "diabetes": 0,
    "totChol": 175,
    "sysBP": 118,
    "diaBP": 76,
    "BMI": 22.8,
    "heartRate": 68,
    "glucose": 92,
}


def predict(user_data: dict) -> dict:
    model_path = MODEL_DIR / "heart_risk_model.joblib"
    model = joblib.load(model_path)

    row = {feature: user_data.get(feature) for feature in FEATURES}
    X = pd.DataFrame([row], columns=FEATURES)

    probability = float(model.predict_proba(X)[0, 1])
    prediction = int(probability >= 0.5)

    # This is a model probability, not a clinically validated 0-100 score.
    return {
        "ten_year_chd_probability": round(probability, 6),
        "ten_year_chd_percentage": round(probability * 100, 2),
        "binary_prediction": prediction,
        "model_version": "heart-risk-v1",
    }


if __name__ == "__main__":
    result = predict(EXAMPLE_USER)
    print(result)
