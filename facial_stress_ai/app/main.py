from pathlib import Path
import os
import shutil
import uuid

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.config import DEVICE
from src.predict import predict

app = FastAPI(
    title="Facial Stress AI API",
    description=(
        "Experimental facial-expression classifier used as supporting "
        "computer-vision context. It is not a medical or psychological diagnosis."
    ),
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

API_PREFIX = "/py-cv"
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

POSITIVE_CLASS_INDEX = int(os.getenv("STRESS_POSITIVE_CLASS_INDEX", "1"))
LABEL_MAPPING_VERIFIED = (
    os.getenv("STRESS_LABEL_MAPPING_VERIFIED", "false").lower() == "true"
)


def _stress_level(score: float | None) -> str:
    if score is None or not LABEL_MAPPING_VERIFIED:
        return "unverified"
    if score < 0.40:
        return "low"
    if score < 0.70:
        return "moderate"
    return "elevated"


def _chatbot_context(response: dict) -> dict:
    prediction = response.get("prediction", {})
    probabilities = response.get("probabilities", {})
    analysis = response.get("analysis", {})

    return {
        "source": "facial_cv_model",
        "prediction": {
            "class_index": prediction.get("class_index"),
            "class_name": prediction.get("class_name"),
            "confidence": prediction.get("confidence"),
        },
        "stress_signal": {
            "score": analysis.get("stress_score"),
            "level": analysis.get("stress_level"),
            "positive_class_index": POSITIVE_CLASS_INDEX,
            "label_mapping_verified": LABEL_MAPPING_VERIFIED,
            "class_0_probability": probabilities.get("class_0"),
            "class_1_probability": probabilities.get("class_1"),
        },
        "guidance": (
            "Use this only as supporting context. Prefer the user's own words. "
            "Do not diagnose stress, anxiety, depression, or any health condition "
            "from facial appearance. Mention uncertainty when confidence is limited "
            "or label mapping is unverified."
        ),
    }


@app.get(f"{API_PREFIX}/")
def root():
    return {
        "message": "Facial Stress AI API is running",
        "status": "online",
        "device": str(DEVICE),
        "api_prefix": API_PREFIX,
        "label_mapping_verified": LABEL_MAPPING_VERIFIED,
        "positive_class_index": POSITIVE_CLASS_INDEX,
        "endpoints": {
            "health": f"{API_PREFIX}/health",
            "model_info": f"{API_PREFIX}/model-info",
            "predict": f"{API_PREFIX}/predict",
        },
    }


@app.get(f"{API_PREFIX}/health")
def health():
    return {
        "status": "healthy",
        "service": "facial-stress-ai",
        "device": str(DEVICE),
    }


@app.get(f"{API_PREFIX}/model-info")
def model_info():
    return {
        "model_name": "Facial Stress CNN",
        "model_version": "V1",
        "status": "production-prototype",
        "input_shape": [1, 48, 48],
        "classes": ["Class 0", "Class 1"],
        "positive_class_index": POSITIVE_CLASS_INDEX,
        "label_mapping_verified": LABEL_MAPPING_VERIFIED,
        "disclaimer": (
            "Experimental visual classification only. Facial appearance alone "
            "cannot establish psychological stress or a diagnosis."
        ),
        "device": str(DEVICE),
    }


@app.post(f"{API_PREFIX}/predict")
async def predict_image(file: UploadFile = File(...)):
    allowed_types = {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
    }

    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Upload JPG, JPEG, PNG, or WEBP.",
        )

    suffix = Path(file.filename or "face.jpg").suffix.lower() or ".jpg"
    file_path = UPLOAD_DIR / f"{uuid.uuid4()}{suffix}"

    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        result = predict(str(file_path))

        if not result.get("success"):
            raise HTTPException(
                status_code=422,
                detail=result.get("error", "Prediction failed"),
            )

        class_0 = float(result["class_0_probability"])
        class_1 = float(result["class_1_probability"])
        stress_score = class_0 if POSITIVE_CLASS_INDEX == 0 else class_1

        response = {
            "success": True,
            "model": {
                "name": "Facial Stress CNN",
                "version": "V1",
            },
            "prediction": {
                "class_index": result["predicted_class_index"],
                "class_name": result["predicted_class"],
                "confidence": round(float(result["confidence"]), 4),
                "confidence_percent": round(float(result["confidence"]) * 100, 2),
            },
            "probabilities": {
                "class_0": round(class_0, 4),
                "class_1": round(class_1, 4),
            },
            "analysis": {
                "stress_score": round(stress_score, 4),
                "stress_score_percent": round(stress_score * 100, 2),
                "stress_level": _stress_level(stress_score),
                "positive_class_index": POSITIVE_CLASS_INDEX,
                "label_mapping_verified": LABEL_MAPPING_VERIFIED,
                "status": (
                    "experimental"
                    if LABEL_MAPPING_VERIFIED
                    else "experimental_unverified_label_mapping"
                ),
            },
            "face_detection": {
                "faces_detected": result["faces_detected"],
                "bounding_box": result["face_bounding_box"],
            },
            "model_epoch": result["model_epoch"],
            "disclaimer": (
                "Experimental visual estimate only. Do not use as a medical "
                "or psychological diagnosis."
            ),
        }

        response["chatbot_context"] = _chatbot_context(response)

        return JSONResponse(content=response)

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Internal prediction error: {error}",
        )
    finally:
        if file_path.exists():
            file_path.unlink()
