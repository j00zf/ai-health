from typing import Any, Dict

from fastapi import (
    FastAPI,
    HTTPException,
    Request,
)

from fastapi.middleware.cors import CORSMiddleware

from fastapi.responses import JSONResponse

from .schemas import (
    AnalyzeRequest,
    HealthResponse,
    ErrorResponse,
)

from prediction.inference import (
    analyze_user,
)


# ============================================================
# APPLICATION CONFIGURATION
# ============================================================

MODEL_VERSION = "v2-deployment"

SERVICE_NAME = "pulse-ai-ml"

API_VERSION = "2.0.0"


# ============================================================
# FASTAPI APPLICATION
# ============================================================

app = FastAPI(

    title="Pulse AI ML API",

    description=(
        "Pulse AI machine-learning inference service "
        "for heart-health, health, wellness, longitudinal "
        "analysis, recommendations and wellbeing forecasting."
    ),

    version=API_VERSION,

    docs_url="/docs",

    redoc_url="/redoc",
)


# ============================================================
# CORS
# ============================================================
#
# Development:
# - localhost
# - 127.0.0.1
#
# Later, replace these with the real Pulse AI frontend domain.
#

ALLOWED_ORIGINS = [

    "http://localhost:3000",

    "http://127.0.0.1:3000",

    "http://localhost:5173",

    "http://127.0.0.1:5173",
]


app.add_middleware(

    CORSMiddleware,

    allow_origins=ALLOWED_ORIGINS,

    allow_credentials=True,

    allow_methods=[
        "GET",
        "POST",
        "OPTIONS",
    ],

    allow_headers=[
        "*"
    ],
)


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root() -> Dict[str, Any]:

    return {

        "service":
            SERVICE_NAME,

        "version":
            API_VERSION,

        "status":
            "online",

        "modelVersion":
            MODEL_VERSION,

        "bloodPressureUsed":
            False,

        "endpoints": {

            "health":
                "/health",

            "analyze":
                "/api/v1/analyze",

            "docs":
                "/docs",

            "redoc":
                "/redoc",
        },
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
            SERVICE_NAME,

        "model_version":
            MODEL_VERSION,

        "blood_pressure_used":
            False,
    }


# ============================================================
# API INFORMATION
# ============================================================

@app.get("/api/v1/info")
def api_info():

    return {

        "service":
            SERVICE_NAME,

        "apiVersion":
            API_VERSION,

        "modelVersion":
            MODEL_VERSION,

        "features": {

            "heartHealth":
                True,

            "generalHealth":
                True,

            "wellness":
                True,

            "longitudinalAnalysis":
                True,

            "recommendations":
                True,

            "forecasting":
                True,

            "explainability":
                True,

            "aiInterpretation":
                True,

        },

        "constraints": {

            "bloodPressureUsed":
                False,

            "medicalDiagnosis":
                False,

            "clinicalDecisionSupport":
                False,

        },
    }


# ============================================================
# ANALYZE USER
# ============================================================

@app.post(
    "/api/v1/analyze",
)
def analyze_user_endpoint(
    request: AnalyzeRequest,
) -> Dict[str, Any]:

    # ========================================================
    # MINIMUM DATA CHECK
    # ========================================================

    record_count = len(
        request.health_records
    )

    # --------------------------------------------------------
    # We allow zero records because the ML baseline can still
    # operate from the user profile.
    #
    # But the longitudinal engine requires records.
    # --------------------------------------------------------

    if record_count > 366:

        raise HTTPException(

            status_code=422,

            detail={
                "error":
                    "too_many_records",

                "message":
                    "A maximum of 366 health records is allowed.",

                "code":
                    "MAX_RECORDS_EXCEEDED",
            },
        )


    # ========================================================
    # CONVERT REQUEST DATA
    # ========================================================

    try:

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


    except Exception as exc:

        raise HTTPException(

            status_code=422,

            detail={
                "error":
                    "invalid_request",

                "message":
                    str(exc),

                "code":
                    "REQUEST_CONVERSION_FAILED",
            },
        )


    # ========================================================
    # RUN PULSE AI
    # ========================================================

    try:

        result = analyze_user(

            profile,

            health_records,
        )


    except ValueError as exc:

        raise HTTPException(

            status_code=422,

            detail={
                "error":
                    "analysis_validation_error",

                "message":
                    str(exc),

                "code":
                    "ANALYSIS_VALIDATION_FAILED",
            },
        )


    except Exception as exc:

        # ----------------------------------------------------
        # Do not expose internal traceback to the client.
        # ----------------------------------------------------

        raise HTTPException(

            status_code=500,

            detail={
                "error":
                    "analysis_failed",

                "message":
                    "Pulse AI analysis could not be completed.",

                "code":
                    "INFERENCE_ERROR",
            },
        )


    # ========================================================
    # ADD API METADATA
    # ========================================================

    result["api"] = {

        "version":
            API_VERSION,

        "service":
            SERVICE_NAME,

        "modelVersion":
            MODEL_VERSION,

        "bloodPressureUsed":
            False,

    }


    # ========================================================
    # DATA AVAILABILITY
    # ========================================================

    result["input"] = {

        "healthRecordsProvided":
            record_count,

        "longitudinalAnalysisAvailable":
            record_count > 0,

        "forecastAvailable":
            record_count > 0,

    }


    # ========================================================
    # SAFETY METADATA
    # ========================================================

    result["safety"] = {

        "medicalDiagnosis":
            False,

        "clinicalDecisionSupport":
            False,

        "wellnessInsightsOnly":
            True,

        "forecastIsProjection":
            True,

        "forecastIsNotDiagnosis":
            True,

    }


    return result


# ============================================================
# GLOBAL HTTP EXCEPTION HANDLER
# ============================================================

@app.exception_handler(
    HTTPException
)
async def http_exception_handler(
    request: Request,
    exc: HTTPException,
):

    return JSONResponse(

        status_code=exc.status_code,

        content={

            "error":
                "request_error",

            "message":
                exc.detail,

            "path":
                request.url.path,
        },
    )


# ============================================================
# GLOBAL UNEXPECTED ERROR HANDLER
# ============================================================

@app.exception_handler(
    Exception
)
async def unexpected_exception_handler(
    request: Request,
    exc: Exception,
):

    return JSONResponse(

        status_code=500,

        content={

            "error":
                "internal_server_error",

            "message":
                "An unexpected server error occurred.",

            "path":
                request.url.path,
        },
    )