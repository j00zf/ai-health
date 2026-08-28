from typing import Any, Dict
import json
import traceback

from fastapi import (
    FastAPI,
    HTTPException,
    Request,
)

from fastapi.exceptions import (
    RequestValidationError,
)

from fastapi.middleware.cors import (
    CORSMiddleware,
)

from fastapi.responses import (
    JSONResponse,
)

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
        "*",
    ],
)


# ============================================================
# REQUEST VALIDATION ERROR HANDLER
#
# IMPORTANT:
# This catches FastAPI/Pydantic validation errors that happen
# BEFORE the /analyze endpoint function is executed.
#
# This is the handler needed to debug your current 422 error.
# ============================================================

@app.exception_handler(RequestValidationError)
async def request_validation_exception_handler(
    request: Request,
    exc: RequestValidationError,
):
    print("\n", flush=True)
    print("=" * 80, flush=True)
    print("❌ FASTAPI REQUEST VALIDATION ERROR (422)", flush=True)
    print("=" * 80, flush=True)

    print(
        f"\nREQUEST METHOD: {request.method}",
        flush=True,
    )

    print(
        f"REQUEST PATH: {request.url.path}",
        flush=True,
    )

    print(
        f"REQUEST URL: {request.url}",
        flush=True,
    )

    print(
        "\nVALIDATION ERRORS:",
        flush=True,
    )

    try:
        validation_errors = exc.errors()

        print(
            json.dumps(
                validation_errors,
                indent=2,
                default=str,
            ),
            flush=True,
        )

    except Exception as log_error:
        validation_errors = exc.errors()

        print(
            f"Could not JSON format validation errors: "
            f"{log_error}",
            flush=True,
        )

        print(
            validation_errors,
            flush=True,
        )

    print(
        "\nRAW REQUEST BODY:",
        flush=True,
    )

    try:
        body = await request.body()

        if body:
            raw_body = body.decode(
                "utf-8",
                errors="replace",
            )

            try:
                parsed_body = json.loads(
                    raw_body,
                )

                print(
                    json.dumps(
                        parsed_body,
                        indent=2,
                        default=str,
                    ),
                    flush=True,
                )

            except Exception:
                print(
                    raw_body,
                    flush=True,
                )

        else:
            print(
                "(EMPTY REQUEST BODY)",
                flush=True,
            )

    except Exception as body_error:
        print(
            f"Could not read request body: {body_error}",
            flush=True,
        )

    print("\n" + "=" * 80, flush=True)
    print(
        "END OF 422 VALIDATION ERROR",
        flush=True,
    )
    print("=" * 80 + "\n", flush=True)

    return JSONResponse(
        status_code=422,

        content={
            "error":
                "validation_error",

            "message":
                "Request validation failed.",

            "detail":
                validation_errors,

            "path":
                request.url.path,
        },
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

    print("\n", flush=True)
    print("=" * 80, flush=True)
    print("🧠 PULSE AI ANALYSIS REQUEST RECEIVED", flush=True)
    print("=" * 80, flush=True)

    print(
        "\n📊 Request accepted by Pydantic validation.",
        flush=True,
    )

    # ========================================================
    # MINIMUM DATA CHECK
    # ========================================================

    record_count = len(
        request.health_records
    )

    print(
        f"\n📈 Health records received: {record_count}",
        flush=True,
    )

    if record_count > 366:
        print(
            "❌ Too many health records.",
            flush=True,
        )

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
        print(
            "\n🔄 Converting profile data...",
            flush=True,
        )

        profile = (
            request.profile.model_dump(
                exclude_none=True,
            )
        )

        print(
            "\n👤 NORMALIZED PROFILE:",
            flush=True,
        )

        print(
            json.dumps(
                profile,
                indent=2,
                default=str,
            ),
            flush=True,
        )


        print(
            "\n🔄 Converting health records...",
            flush=True,
        )

        health_records = [
            record.model_dump(
                exclude_none=True,
            )

            for record
            in request.health_records
        ]


        print(
            f"\n📊 CONVERTED HEALTH RECORDS: "
            f"{len(health_records)}",
            flush=True,
        )


        if health_records:
            print(
                "\n📋 LATEST HEALTH RECORD:",
                flush=True,
            )

            print(
                json.dumps(
                    health_records[-1],
                    indent=2,
                    default=str,
                ),
                flush=True,
            )

        else:
            print(
                "\n⚠️ No health records provided.",
                flush=True,
            )


    except Exception as exc:
        print(
            "\n❌ REQUEST CONVERSION FAILED",
            flush=True,
        )

        print(
            f"Error type: {type(exc).__name__}",
            flush=True,
        )

        print(
            f"Error message: {str(exc)}",
            flush=True,
        )

        traceback.print_exc()

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
        print(
            "\n🤖 STARTING PULSE AI INFERENCE...",
            flush=True,
        )

        result = analyze_user(
            profile,
            health_records,
        )

        print(
            "\n✅ PULSE AI INFERENCE COMPLETED",
            flush=True,
        )

        if not isinstance(
            result,
            dict,
        ):
            raise ValueError(
                "Pulse AI inference did not return a dictionary."
            )

        print(
            "\n📦 RESULT KEYS:",
            flush=True,
        )

        print(
            list(result.keys()),
            flush=True,
        )


    except ValueError as exc:
        print(
            "\n❌ ANALYSIS VALIDATION ERROR",
            flush=True,
        )

        print(
            f"Error: {str(exc)}",
            flush=True,
        )

        traceback.print_exc()

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


    except HTTPException:
        raise


    except Exception as exc:
        print(
            "\n❌ PULSE AI INFERENCE ERROR",
            flush=True,
        )

        print(
            f"Error type: {type(exc).__name__}",
            flush=True,
        )

        print(
            f"Error message: {str(exc)}",
            flush=True,
        )

        print(
            "\nFULL TRACEBACK:",
            flush=True,
        )

        traceback.print_exc()

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


    print("\n" + "=" * 80, flush=True)
    print(
        "🎉 PULSE AI REQUEST COMPLETED SUCCESSFULLY",
        flush=True,
    )
    print("=" * 80 + "\n", flush=True)

    return result


# ============================================================
# GLOBAL HTTP EXCEPTION HANDLER
# ============================================================

@app.exception_handler(
    HTTPException,
)
async def http_exception_handler(
    request: Request,
    exc: HTTPException,
):

    print("\n", flush=True)
    print("=" * 80, flush=True)
    print(
        f"⚠️ HTTP EXCEPTION: {exc.status_code}",
        flush=True,
    )
    print("=" * 80, flush=True)

    print(
        f"PATH: {request.url.path}",
        flush=True,
    )

    print(
        "DETAIL:",
        flush=True,
    )

    print(
        json.dumps(
            exc.detail,
            indent=2,
            default=str,
        )
        if isinstance(
            exc.detail,
            (dict, list),
        )
        else str(exc.detail),
        flush=True,
    )

    print("=" * 80 + "\n", flush=True)

    return JSONResponse(
        status_code=exc.status_code,

        content={
            "error":
                (
                    exc.detail.get(
                        "error",
                        "request_error",
                    )
                    if isinstance(
                        exc.detail,
                        dict,
                    )
                    else "request_error"
                ),

            "message":
                (
                    exc.detail.get(
                        "message",
                        str(exc.detail),
                    )
                    if isinstance(
                        exc.detail,
                        dict,
                    )
                    else str(exc.detail)
                ),

            "code":
                (
                    exc.detail.get(
                        "code",
                    )
                    if isinstance(
                        exc.detail,
                        dict,
                    )
                    else None
                ),

            "detail":
                exc.detail,

            "path":
                request.url.path,
        },
    )


# ============================================================
# GLOBAL UNEXPECTED ERROR HANDLER
# ============================================================

@app.exception_handler(
    Exception,
)
async def unexpected_exception_handler(
    request: Request,
    exc: Exception,
):

    print("\n", flush=True)
    print("=" * 80, flush=True)
    print(
        "💥 UNEXPECTED SERVER ERROR",
        flush=True,
    )
    print("=" * 80, flush=True)

    print(
        f"PATH: {request.url.path}",
        flush=True,
    )

    print(
        f"ERROR TYPE: {type(exc).__name__}",
        flush=True,
    )

    print(
        f"ERROR MESSAGE: {str(exc)}",
        flush=True,
    )

    print(
        "\nFULL TRACEBACK:",
        flush=True,
    )

    traceback.print_exc()

    print("=" * 80 + "\n", flush=True)

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