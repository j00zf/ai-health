from pathlib import Path
import sys

import cv2
import torch
from PIL import Image

from src.config import (
    DEVICE,
    CLASS_NAMES
)

from src.model import FacialStressModel

from src.face_detector import (
    detect_face
)

from src.augmentations import (
    EVAL_TRANSFORM
)


# ============================================================
# MODEL PATH
# ============================================================

MODEL_PATH = Path(
    "models/facial_stress_model_v2.pth"
)


# ============================================================
# LOAD MODEL
# ============================================================

def load_model():

    if not MODEL_PATH.exists():

        raise FileNotFoundError(

            f"V2 model not found:\n{MODEL_PATH}\n\n"

            "Please train the V2 model first:\n"

            "python -m src.train_v2"

        )


    model = FacialStressModel(
        num_classes=2
    )


    checkpoint = torch.load(

        MODEL_PATH,

        map_location=DEVICE,

        weights_only=False

    )


    model.load_state_dict(

        checkpoint[
            "model_state_dict"
        ]

    )


    model = model.to(
        DEVICE
    )


    model.eval()


    return model, checkpoint


# ============================================================
# PREPROCESS FACE
# ============================================================

def preprocess_face(face_image):

    # --------------------------------------
    # OpenCV BGR → RGB
    # --------------------------------------

    face_rgb = cv2.cvtColor(

        face_image,

        cv2.COLOR_BGR2RGB

    )


    # --------------------------------------
    # Convert to PIL Image
    # --------------------------------------

    image = Image.fromarray(
        face_rgb
    )


    # --------------------------------------
    # Apply V2 evaluation transform
    #
    # Important:
    # No random augmentation during prediction.
    # --------------------------------------

    image_tensor = EVAL_TRANSFORM(
        image
    )


    # --------------------------------------
    # Add batch dimension
    # --------------------------------------

    image_tensor = image_tensor.unsqueeze(
        0
    )


    return image_tensor


# ============================================================
# MAKE PREDICTION
# ============================================================

def predict(image_path):

    # --------------------------------------
    # CHECK IMAGE EXISTS
    # --------------------------------------

    image_path = Path(
        image_path
    )


    if not image_path.exists():

        return {

            "success": False,

            "error":

                f"Image not found: {image_path}"

        }


    # --------------------------------------
    # DETECT FACE
    # --------------------------------------

    face_result = detect_face(
        str(image_path)
    )


    if face_result is None:

        return {

            "success": False,

            "error":

                "No face detected in image"

        }


    # --------------------------------------
    # LOAD V2 MODEL
    # --------------------------------------

    model, checkpoint = load_model()


    # --------------------------------------
    # PREPROCESS FACE
    # --------------------------------------

    image_tensor = preprocess_face(

        face_result[
            "face_image"
        ]

    )


    image_tensor = image_tensor.to(
        DEVICE
    )


    # --------------------------------------
    # MODEL INFERENCE
    # --------------------------------------

    with torch.no_grad():

        outputs = model(
            image_tensor
        )


        probabilities = torch.softmax(

            outputs,

            dim=1

        )


    # --------------------------------------
    # PREDICT CLASS
    # --------------------------------------

    predicted_index = torch.argmax(

        probabilities,

        dim=1

    ).item()


    probabilities = (

        probabilities
        .squeeze()
        .cpu()

    )


    class_0_probability = float(

        probabilities[0].item()

    )


    class_1_probability = float(

        probabilities[1].item()

    )


    confidence = float(

        probabilities[
            predicted_index
        ].item()

    )


    # --------------------------------------
    # CREATE RESULT
    # --------------------------------------

    result = {

        "success": True,

        "model_version":

            "V2",

        "predicted_class_index":

            predicted_index,

        "predicted_class":

            CLASS_NAMES[
                predicted_index
            ],

        "confidence":

            confidence,

        "class_0_probability":

            class_0_probability,

        "class_1_probability":

            class_1_probability,

        "model_epoch":

            checkpoint.get(
                "epoch"
            ),

        "faces_detected":

            face_result[
                "faces_detected"
            ],

        "face_bounding_box":

            face_result[
                "bounding_box"
            ]

    }


    return result


# ============================================================
# COMMAND LINE
# ============================================================

def main():

    if len(sys.argv) < 2:

        print(
            "\nUsage:"
        )

        print(
            "python -m src.predict_v2 "
            "path/to/image.jpg"
        )

        return


    image_path = sys.argv[1]


    print("=" * 60)

    print(
        "FACIAL STRESS MODEL V2 PREDICTION"
    )

    print("=" * 60)


    result = predict(
        image_path
    )


    # --------------------------------------
    # ERROR
    # --------------------------------------

    if not result["success"]:

        print(

            f"\nError: "

            f"{result['error']}"

        )

        return


    # --------------------------------------
    # RESULTS
    # --------------------------------------

    print(

        f"\nModel Version: "

        f"{result['model_version']}"

    )


    print(

        f"\nFaces detected: "

        f"{result['faces_detected']}"

    )


    print(
        "\nFace bounding box:"
    )


    print(

        result[
            "face_bounding_box"
        ]

    )


    print(

        f"\nPredicted Class: "

        f"{result['predicted_class']}"

    )


    print(

        f"Confidence: "

        f"{result['confidence'] * 100:.2f}%"

    )


    print(

        f"\nNon-Stress Probability: "

        f"{result['class_0_probability'] * 100:.2f}%"

    )


    print(

        f"Stress Probability: "

        f"{result['class_1_probability'] * 100:.2f}%"

    )


    print(

        f"\nModel Best Epoch: "

        f"{result['model_epoch']}"

    )


    print("\n" + "=" * 60)

    print(
        "V2 PREDICTION COMPLETE"
    )

    print("=" * 60)


if __name__ == "__main__":

    main()