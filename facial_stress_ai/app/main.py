from pathlib import Path
import shutil
import uuid

from fastapi import (
    FastAPI,
    File,
    HTTPException,
    UploadFile
)

from fastapi.responses import JSONResponse

from src.config import DEVICE
from src.predict import predict


# ============================================================
# APPLICATION
# ============================================================

app = FastAPI(

    title="Facial Stress AI API",

    description=(
        "Experimental facial expression "
        "classification API"
    ),

    version="1.0.0"

)


# ============================================================
# API PREFIX
# ============================================================

API_PREFIX = "/py-cv"


# ============================================================
# PATHS
# ============================================================

UPLOAD_DIR = Path(
    "uploads"
)

UPLOAD_DIR.mkdir(

    parents=True,

    exist_ok=True

)


# ============================================================
# ROOT ENDPOINT
# ============================================================

@app.get(
    f"{API_PREFIX}/"
)

def root():

    return {

        "message":

            "Facial Stress AI API is running",

        "status":

            "online",

        "device":

            str(DEVICE),

        "api_prefix":

            API_PREFIX,

        "endpoints": {

            "health":

                f"{API_PREFIX}/health",

            "model_info":

                f"{API_PREFIX}/model-info",

            "predict":

                f"{API_PREFIX}/predict"

        }

    }


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get(
    f"{API_PREFIX}/health"
)

def health():

    return {

        "status":

            "healthy",

        "service":

            "facial-stress-ai",

        "device":

            str(DEVICE)

    }


# ============================================================
# MODEL INFORMATION
# ============================================================

@app.get(
    f"{API_PREFIX}/model-info"
)

def model_info():

    return {

        "model_name":

            "Facial Stress CNN",

        "model_version":

            "V1",

        "status":

            "production",

        "input_shape":

            [

                1,

                48,

                48

            ],

        "classes":

            [

                "Class 0",

                "Class 1"

            ],

        "device":

            str(DEVICE)

    }


# ============================================================
# IMAGE PREDICTION
# ============================================================

@app.post(
    f"{API_PREFIX}/predict"
)

async def predict_image(

    file: UploadFile = File(...)

):

    # --------------------------------------------------------
    # VALIDATE FILE TYPE
    # --------------------------------------------------------

    allowed_types = [

        "image/jpeg",

        "image/jpg",

        "image/png",

        "image/webp"

    ]


    if file.content_type not in allowed_types:

        raise HTTPException(

            status_code=400,

            detail=(
                "Invalid file type. "
                "Please upload JPG, JPEG, PNG, or WEBP."
            )

        )


    # --------------------------------------------------------
    # CREATE UNIQUE FILE NAME
    # --------------------------------------------------------

    suffix = Path(

        file.filename

    ).suffix.lower()


    if not suffix:

        suffix = ".jpg"


    unique_filename = (

        f"{uuid.uuid4()}{suffix}"

    )


    file_path = (

        UPLOAD_DIR

        /

        unique_filename

    )


    # --------------------------------------------------------
    # SAVE UPLOADED FILE
    # --------------------------------------------------------

    try:

        with open(

            file_path,

            "wb"

        ) as buffer:

            shutil.copyfileobj(

                file.file,

                buffer

            )


        # ----------------------------------------------------
        # RUN MODEL PREDICTION
        # ----------------------------------------------------

        result = predict(

            str(file_path)

        )


        # ----------------------------------------------------
        # HANDLE PREDICTION ERROR
        # ----------------------------------------------------

        if not result.get(

            "success"

        ):

            raise HTTPException(

                status_code=422,

                detail=result.get(

                    "error",

                    "Prediction failed"

                )

            )


        # ----------------------------------------------------
        # CREATE API RESPONSE
        # ----------------------------------------------------

        response = {

            "success":

                True,


            "model": {

                "name":

                    "Facial Stress CNN",


                "version":

                    "V1"

            },


            "prediction": {

                "class_index":

                    result[
                        "predicted_class_index"
                    ],


                "class_name":

                    result[
                        "predicted_class"
                    ],


                "confidence":

                    round(

                        result[
                            "confidence"
                        ],

                        4

                    ),


                "confidence_percent":

                    round(

                        result[
                            "confidence"
                        ]

                        * 100,

                        2

                    )

            },


            "probabilities": {

                "class_0":

                    round(

                        result[
                            "class_0_probability"
                        ],

                        4

                    ),


                "class_1":

                    round(

                        result[
                            "class_1_probability"
                        ],

                        4

                    )

            },


            "face_detection": {

                "faces_detected":

                    result[
                        "faces_detected"
                    ],


                "bounding_box":

                    result[
                        "face_bounding_box"
                    ]

            },


            "model_epoch":

                result[
                    "model_epoch"
                ]

        }


        return JSONResponse(

            content=response

        )


    except HTTPException:

        raise


    except Exception as error:

        raise HTTPException(

            status_code=500,

            detail=(

                "Internal prediction error: "

                f"{str(error)}"

            )

        )


    finally:

        # ----------------------------------------------------
        # CLEAN UP TEMPORARY UPLOAD
        # ----------------------------------------------------

        if file_path.exists():

            file_path.unlink()


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":

    import uvicorn


    uvicorn.run(

        "app.main:app",

        host="0.0.0.0",

        port=8000,

        reload=True

    )