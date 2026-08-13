import os
from pathlib import Path
from typing import Optional

import joblib
import numpy as np
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

# -----------------------------------------------------------------------------
# CONFIG
# -----------------------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = Path(
    os.getenv(
        "STRESS_MODEL_PATH",
        str(BASE_DIR / "models" / "stress_xgb.joblib"),
    )
)

MODEL_VERSION = os.getenv("STRESS_MODEL_VERSION", "1.0.0")

app = FastAPI(
    title="Beaver Tech Facial Stress Analysis API",
    description=(
        "Non-clinical facial stress estimation service. "
        "The service accepts extracted facial features rather than raw images."
    ),
    version=MODEL_VERSION,
)

_model = None


# -----------------------------------------------------------------------------
# MODEL
# -----------------------------------------------------------------------------

def load_model():
    global _model

    if _model is not None:
        return _model

    if not MODEL_PATH.exists():
        return None

    try:
        _model = joblib.load(MODEL_PATH)
        return _model
    except Exception as exc:
        raise RuntimeError(
            f"Unable to load stress model: {exc}"
        ) from exc


# -----------------------------------------------------------------------------
# INPUT SCHEMAS
# -----------------------------------------------------------------------------

class EyeSignals(BaseModel):
    leftEyeOpenness: float = Field(
        default=0.0,
        ge=0.0,
        le=1.0,
    )

    rightEyeOpenness: float = Field(
        default=0.0,
        ge=0.0,
        le=1.0,
    )

    blinkCount: int = Field(
        default=0,
        ge=0,
    )

    prolongedEyeClosure: bool = False


class HeadPose(BaseModel):
    yaw: float = 0.0
    pitch: float = 0.0
    roll: float = 0.0


class ImageQuality(BaseModel):
    faceDetected: bool = False

    faceConfidence: float = Field(
        default=0.0,
        ge=0.0,
        le=1.0,
    )

    faceSizeRatio: float = Field(
        default=0.0,
        ge=0.0,
        le=1.0,
    )


class DerivedSignals(BaseModel):
    visualFatigueScore: float = Field(
        default=0.0,
        ge=0.0,
        le=1.0,
    )

    alertnessScore: float = Field(
        default=0.0,
        ge=0.0,
        le=1.0,
    )


class StressRequest(BaseModel):
    eyeSignals: EyeSignals

    headPose: HeadPose = Field(
        default_factory=HeadPose,
    )

    imageQuality: ImageQuality = Field(
        default_factory=ImageQuality,
    )

    derivedSignals: DerivedSignals = Field(
        default_factory=DerivedSignals,
    )

    scanDurationSeconds: float = Field(
        default=0.0,
        ge=0.0,
    )

    sampleCount: int = Field(
        default=1,
        ge=1,
    )


# -----------------------------------------------------------------------------
# FEATURES
#
# These MUST remain in the same order used by train_model.py.
# -----------------------------------------------------------------------------

FEATURE_NAMES = [
    "left_eye_openness",
    "right_eye_openness",
    "eye_openness_mean",
    "eye_closure",
    "blink_count",
    "prolonged_closure",
    "visual_fatigue",
    "alertness",
    "abs_yaw",
    "abs_pitch",
    "abs_roll",
    "face_confidence",
    "face_size_ratio",
    "sample_count",
]


def build_features(request: StressRequest) -> np.ndarray:
    left = float(request.eyeSignals.leftEyeOpenness)
    right = float(request.eyeSignals.rightEyeOpenness)

    eye_mean = (left + right) / 2.0
    eye_closure = 1.0 - eye_mean

    values = [
        left,
        right,
        eye_mean,
        eye_closure,
        float(request.eyeSignals.blinkCount),
        float(request.eyeSignals.prolongedEyeClosure),
        float(request.derivedSignals.visualFatigueScore),
        float(request.derivedSignals.alertnessScore),
        abs(float(request.headPose.yaw)),
        abs(float(request.headPose.pitch)),
        abs(float(request.headPose.roll)),
        float(request.imageQuality.faceConfidence),
        float(request.imageQuality.faceSizeRatio),
        float(request.sampleCount),
    ]

    return np.asarray(
        values,
        dtype=np.float32,
    ).reshape(1, -1)


# -----------------------------------------------------------------------------
# FALLBACK BASELINE
#
# This is ONLY for development when a trained model has not been installed.
# It is NOT a medically validated stress detector.
# -----------------------------------------------------------------------------

def fallback_stress_score(request: StressRequest) -> float:
    left = request.eyeSignals.leftEyeOpenness
    right = request.eyeSignals.rightEyeOpenness

    eye_mean = (left + right) / 2.0

    eye_closure = np.clip(
        1.0 - eye_mean,
        0.0,
        1.0,
    )

    fatigue = request.derivedSignals.visualFatigueScore

    low_alertness = np.clip(
        1.0 - request.derivedSignals.alertnessScore,
        0.0,
        1.0,
    )

    prolonged_closure = (
        1.0
        if request.eyeSignals.prolongedEyeClosure
        else 0.0
    )

    blink_component = np.clip(
        request.eyeSignals.blinkCount / 8.0,
        0.0,
        1.0,
    )

    pose_component = np.mean(
        [
            np.clip(abs(request.headPose.yaw) / 30.0, 0.0, 1.0),
            np.clip(abs(request.headPose.pitch) / 30.0, 0.0, 1.0),
            np.clip(abs(request.headPose.roll) / 25.0, 0.0, 1.0),
        ]
    )

    score = (
        0.35 * fatigue
        + 0.25 * eye_closure
        + 0.20 * low_alertness
        + 0.10 * prolonged_closure
        + 0.05 * blink_component
        + 0.05 * pose_component
    )

    return float(np.clip(score, 0.0, 1.0))


# -----------------------------------------------------------------------------
# RESULT HELPERS
# -----------------------------------------------------------------------------

def stress_level(score: float) -> str:
    if score < 0.33:
        return "low"

    if score < 0.66:
        return "moderate"

    return "high"


def score_to_confidence(score: float) -> float:
    # Probability distance from 0.5.
    # This is model confidence for the classification result,
    # not medical confidence.
    return float(
        np.clip(
            2.0 * abs(score - 0.5),
            0.0,
            1.0,
        )
    )


def predict_with_model(
    model,
    features: np.ndarray,
) -> float:
    if not hasattr(model, "predict_proba"):
        prediction = model.predict(features)

        return float(
            np.asarray(prediction).reshape(-1)[0]
        )

    probabilities = model.predict_proba(features)[0]

    classes = getattr(
        model,
        "classes_",
        np.arange(len(probabilities)),
    )

    classes = list(classes)

    # Binary model convention:
    # 0 = non-stress
    # 1 = stress
    if 1 in classes:
        stress_index = classes.index(1)
    else:
        stress_index = int(
            np.argmax(probabilities)
        )

    return float(
        np.clip(
            probabilities[stress_index],
            0.0,
            1.0,
        )
    )


# -----------------------------------------------------------------------------
# HEALTH
# -----------------------------------------------------------------------------

@app.get("/")
def root():
    return {
        "success": True,
        "service": "facial-stress-analysis",
        "version": MODEL_VERSION,
        "modelInstalled": MODEL_PATH.exists(),
    }


@app.get("/health")
def health():
    model = load_model()

    return {
        "success": True,
        "status": "healthy",
        "modelLoaded": model is not None,
        "modelPath": str(MODEL_PATH),
        "modelVersion": MODEL_VERSION,
    }


# -----------------------------------------------------------------------------
# PREDICT
# -----------------------------------------------------------------------------

@app.post("/predict")
def predict(request: StressRequest):
    if not request.imageQuality.faceDetected:
        raise HTTPException(
            status_code=400,
            detail="No face detected.",
        )

    if request.imageQuality.faceConfidence < 0.15:
        raise HTTPException(
            status_code=400,
            detail="Face detection confidence is too low.",
        )

    features = build_features(request)

    model = load_model()

    if model is not None:
        score = predict_with_model(
            model,
            features,
        )

        method = "trained_xgboost"
        model_name = "xgboost"
    else:
        score = fallback_stress_score(request)

        method = "fallback_baseline"
        model_name = "baseline"

    level = stress_level(score)

    return {
        "success": True,
        "stressScore": round(score, 4),
        "stressLevel": level,
        "stressConfidence": round(
            score_to_confidence(score),
            4,
        ),
        "method": method,
        "model": model_name,
        "modelVersion": MODEL_VERSION,
        "clinical": False,
        "message": (
            "Facial stress estimation is a non-clinical "
            "indicator and should not be used as a diagnosis."
        ),
    }


# -----------------------------------------------------------------------------
# BATCH PREDICTION
#
# Useful if Flutter sends several scan windows at once.
# -----------------------------------------------------------------------------

class BatchStressRequest(BaseModel):
    samples: list[StressRequest]


@app.post("/predict/batch")
def predict_batch(request: BatchStressRequest):
    if not request.samples:
        raise HTTPException(
            status_code=400,
            detail="At least one sample is required.",
        )

    results = []

    for sample in request.samples:
        result = predict(sample)
        results.append(result)

    scores = [
        item["stressScore"]
        for item in results
    ]

    average_score = float(
        np.mean(scores)
    )

    return {
        "success": True,
        "stressScore": round(
            average_score,
            4,
        ),
        "stressLevel": stress_level(
            average_score
        ),
        "stressConfidence": round(
            score_to_confidence(
                average_score
            ),
            4,
        ),
        "sampleCount": len(results),
        "clinical": False,
    }