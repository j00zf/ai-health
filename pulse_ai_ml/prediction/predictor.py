from pathlib import Path
from typing import Any, Dict, Optional

import joblib
import pandas as pd


# ============================================================
# PATHS
# ============================================================

ROOT = (
    Path(__file__)
    .resolve()
    .parents[1]
)

MODEL_DIR = ROOT / "models"


# ============================================================
# DEPLOYMENT FEATURES
# ============================================================

FEATURES = [
    "age",
    "sex",

    "height_cm",
    "weight_kg",
    "bmi",
    "waist_cm",

    "heart_rate",

    "activity_minutes",

    "sleep_hours",

    "smoking",
    "alcohol",
]


# ============================================================
# MODEL FILES
# ============================================================

MODEL_FILES = {
    "heart": "pulse_heart_v2_deployment.joblib",
    "health": "pulse_health_v2_deployment.joblib",
    "wellness": "pulse_wellness_v2_deployment.joblib",
}


# ============================================================
# PREDICTOR
# ============================================================

class PulsePredictor:

    def __init__(self):

        self.models = {}

        self._load_models()


    # ========================================================
    # LOAD MODELS
    # ========================================================

    def _load_models(self):

        for name, filename in MODEL_FILES.items():

            path = MODEL_DIR / filename

            if not path.exists():

                raise FileNotFoundError(
                    f"\nModel not found:\n"
                    f"{path}\n\n"
                    f"Run:\n"
                    f"python training\\train.py"
                )

            print(
                f"[ML] Loading {name} model..."
            )

            self.models[name] = joblib.load(
                path
            )

        print(
            "[ML] All Pulse AI models loaded."
        )


    # ========================================================
    # VALIDATE INPUT
    # ========================================================

    @staticmethod
    def _validate_input(
        data: Dict[str, Any]
    ):

        # ----------------------------------------------------
        # BP must NEVER enter this deployment model
        # ----------------------------------------------------

        forbidden_features = [
            "systolic_bp",
            "diastolic_bp",
            "blood_pressure",
            "bloodPressure",
        ]

        supplied_forbidden = [
            key
            for key in forbidden_features
            if key in data
        ]

        if supplied_forbidden:

            raise ValueError(
                "Blood pressure fields are not supported "
                "by the deployment model: "
                +
                ", ".join(
                    supplied_forbidden
                )
            )


    # ========================================================
    # PREPARE FEATURES
    # ========================================================

    @staticmethod
    def _prepare_features(
        data: Dict[str, Any]
    ) -> pd.DataFrame:

        row = {}

        for feature in FEATURES:

            row[feature] = data.get(
                feature
            )

        frame = pd.DataFrame(
            [row],
            columns=FEATURES
        )

        # Convert all model inputs to numeric.
        # Missing values are handled by the trained
        # imputer inside the model pipeline.

        for feature in FEATURES:

            frame[feature] = pd.to_numeric(
                frame[feature],
                errors="coerce"
            )

        return frame


    # ========================================================
    # RISK PROBABILITY → SCORE
    # ========================================================
    #
    # Heart and Health:
    #
    # target = 1 means unfavorable outcome
    #
    # Therefore:
    #
    # probability 0.00 → score 100
    # probability 1.00 → score 0
    #
    # ========================================================

    @staticmethod
    def _risk_probability_to_score(
        probability: float
    ) -> float:

        probability = max(
            0.0,
            min(
                1.0,
                probability
            )
        )

        return round(
            (1.0 - probability)
            * 100.0,
            2
        )


    # ========================================================
    # POSITIVE PROBABILITY → SCORE
    # ========================================================
    #
    # Wellness:
    #
    # target = 1 means favorable wellness
    #
    # Therefore:
    #
    # probability 0.00 → score 0
    # probability 1.00 → score 100
    #
    # ========================================================

    @staticmethod
    def _positive_probability_to_score(
        probability: float
    ) -> float:

        probability = max(
            0.0,
            min(
                1.0,
                probability
            )
        )

        return round(
            probability
            * 100.0,
            2
        )


    # ========================================================
    # PREDICT
    # ========================================================

    def predict(
        self,
        data: Dict[str, Any]
    ) -> Dict[str, Any]:

        self._validate_input(
            data
        )

        X = self._prepare_features(
            data
        )


        # ====================================================
        # HEART
        # ====================================================

        heart_probability = float(
            self.models["heart"]
            .predict_proba(X)[0][1]
        )

        heart_score = (
            self._risk_probability_to_score(
                heart_probability
            )
        )


        # ====================================================
        # HEALTH
        # ====================================================

        health_probability = float(
            self.models["health"]
            .predict_proba(X)[0][1]
        )

        health_score = (
            self._risk_probability_to_score(
                health_probability
            )
        )


        # ====================================================
        # WELLNESS
        # ====================================================

        wellness_probability = float(
            self.models["wellness"]
            .predict_proba(X)[0][1]
        )

        wellness_score = (
            self._positive_probability_to_score(
                wellness_probability
            )
        )


        # ====================================================
        # RESULT
        # ====================================================

        return {

            "heart": {

                "probability":
                    heart_probability,

                "score":
                    heart_score,

                "interpretation":
                    "lower modeled unfavorable "
                    "cardiometabolic outcome probability",
            },


            "health": {

                "probability":
                    health_probability,

                "score":
                    health_score,

                "interpretation":
                    "lower modeled unfavorable "
                    "health outcome probability",
            },


            "wellness": {

                "probability":
                    wellness_probability,

                "score":
                    wellness_score,

                "interpretation":
                    "higher modeled favorable "
                    "wellness probability",
            },


            "model_version":
                "v2-deployment",

            "blood_pressure_used":
                False,

            "features_used":
                FEATURES,
        }


# ============================================================
# SINGLETON
# ============================================================

_predictor: Optional[
    PulsePredictor
] = None


def get_predictor() -> PulsePredictor:

    global _predictor

    if _predictor is None:

        _predictor = PulsePredictor()

    return _predictor