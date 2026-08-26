from typing import Any

from fastapi import FastAPI, HTTPException

from .schemas import (
    AnalyzeRequest,
    HealthResponse,
)

from prediction.inference import (
    analyze_user,
)


# ============================================================
# APPLICATION
# ============================================================

app = FastAPI(

    title="Pulse AI ML API",

    description=(
        "Pulse AI wellbeing inference service. "
        "Provides heart-health, health, wellness, "
        "longitudinal analysis, forecasting and "
        "grounded AI interpretation."
    ),

    version="2.0.0",
)


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():

    return {

        "service":
            "Pulse AI ML API",

        "version":
            "2.0.0",

        "status":
            "online",

        "modelVersion":
            "v2-deployment",

        "bloodPressureUsed":
            False,
    }


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get(
    "/health",
    response_model=HealthResponse,
)
def health_check():

    return {

        "status":
            "healthy",

        "service":
            "pulse-ai-ml",

        "model_version":
            "v2-deployment",
    }


# ============================================================
# ANALYZE USER
# ============================================================

@app.post(
    "/api/v1/analyze",
)
def analyze(
    request: AnalyzeRequest,
) -> Any:

    try:

        # ----------------------------------------------------
        # Convert Pydantic objects into normal dictionaries
        # ----------------------------------------------------

        profile = (
            request.profile.model_dump(
                exclude_none=True
            )
        )

        health_records = [

            record.model_dump(
                exclude_none=True
            )

            for record
            in request.health_records
        ]


        # ----------------------------------------------------
        # Run the complete Pulse AI pipeline
        # ----------------------------------------------------

        result = analyze_user(

            profile,

            health_records,
        )


        # ----------------------------------------------------
        # Return complete analysis
        # ----------------------------------------------------

        return result


    except Exception as exc:

        raise HTTPException(

            status_code=500,

            detail={
                "error":
                    "Pulse AI analysis failed",

                "message":
                    str(exc),
            },
        )