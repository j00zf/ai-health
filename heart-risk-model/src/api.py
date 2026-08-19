from __future__ import annotations

from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from .predict_v3 import predict_heart_risk


# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI(
    title="Heart Risk Prediction API",
    description=(
        "Inference API for the Heart Risk V3 "
        "machine learning model."
    ),
    version="3.0.0",
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# REQUEST MODEL
# ============================================================

class HeartRiskRequest(BaseModel):

    male: int = Field(
        ...,
        ge=0,
        le=1,
    )

    age: float = Field(
        ...,
        ge=18,
        le=120,
    )

    education: Optional[float] = Field(
        None,
        ge=1,
        le=4,
    )

    currentSmoker: int = Field(
        ...,
        ge=0,
        le=1,
    )

    cigsPerDay: Optional[float] = Field(
        None,
        ge=0,
        le=100,
    )

    BPMeds: Optional[float] = Field(
        None,
        ge=0,
        le=1,
    )

    prevalentStroke: int = Field(
        ...,
        ge=0,
        le=1,
    )

    prevalentHyp: int = Field(
        ...,
        ge=0,
        le=1,
    )

    diabetes: int = Field(
        ...,
        ge=0,
        le=1,
    )

    totChol: Optional[float] = Field(
        None,
        ge=50,
        le=1000,
    )

    sysBP: float = Field(
        ...,
        ge=50,
        le=300,
    )

    diaBP: float = Field(
        ...,
        ge=30,
        le=200,
    )

    BMI: Optional[float] = Field(
        None,
        ge=10,
        le=80,
    )

    heartRate: Optional[float] = Field(
        None,
        ge=20,
        le=250,
    )

    glucose: Optional[float] = Field(
        None,
        ge=20,
        le=1000,
    )


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/")
def root():

    return {
        "service":
            "Heart Risk Prediction API",

        "model":
            "heart-risk-v3",

        "status":
            "running",
    }


@app.get("/health")
def health():

    return {
        "status":
            "healthy",

        "model":
            "heart-risk-v3",
    }


# ============================================================
# PREDICTION
# ============================================================

@app.post("/predict")
def predict(
    request: HeartRiskRequest
):

    try:

        user_data = (
            request.model_dump()
        )

        result = (
            predict_heart_risk(
                user_data
            )
        )

        return {
            "success": True,
            "prediction": result,
        }

    except ValueError as exc:

        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )

    except Exception as exc:

        raise HTTPException(
            status_code=500,
            detail=(
                "Prediction failed: "
                + str(exc)
            ),
        )