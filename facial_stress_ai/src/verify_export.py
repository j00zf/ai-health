from pathlib import Path
import json

import torch

from src.config import DEVICE
from src.model import FacialStressModel


# ============================================================
# PATHS
# ============================================================

MODEL_PATH = Path(
    "models/production_model.pt"
)

METADATA_PATH = Path(
    "models/production_model_metadata.json"
)


# ============================================================
# LOAD METADATA
# ============================================================

def load_metadata():

    if not METADATA_PATH.exists():

        raise FileNotFoundError(

            f"\nMetadata file not found:\n"
            f"{METADATA_PATH}"

        )


    with open(

        METADATA_PATH,

        "r",

        encoding="utf-8"

    ) as file:

        metadata = json.load(
            file
        )


    return metadata


# ============================================================
# LOAD PRODUCTION MODEL
# ============================================================

def load_production_model():

    if not MODEL_PATH.exists():

        raise FileNotFoundError(

            f"\nProduction model not found:\n"
            f"{MODEL_PATH}"

        )


    checkpoint = torch.load(

        MODEL_PATH,

        map_location=DEVICE,

        weights_only=False

    )


    num_classes = checkpoint.get(

        "num_classes",

        2

    )


    model = FacialStressModel(

        num_classes=num_classes

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
# VERIFY MODEL
# ============================================================

def verify_model():

    print("=" * 70)

    print(
        "PRODUCTION MODEL VERIFICATION"
    )

    print("=" * 70)


    # --------------------------------------------------------
    # LOAD METADATA
    # --------------------------------------------------------

    print(
        "\nLoading metadata..."
    )


    metadata = load_metadata()


    print(
        "Metadata loaded successfully."
    )


    # --------------------------------------------------------
    # LOAD MODEL
    # --------------------------------------------------------

    print(
        "\nLoading production model..."
    )


    model, checkpoint = (

        load_production_model()

    )


    print(
        "Production model loaded successfully."
    )


    # --------------------------------------------------------
    # DISPLAY MODEL INFORMATION
    # --------------------------------------------------------

    print("\n" + "-" * 70)

    print(
        "MODEL INFORMATION"
    )

    print("-" * 70)


    print(

        f"\nModel name: "
        f"{metadata.get('model_name')}"

    )


    print(

        f"Model version: "
        f"{metadata.get('model_version')}"

    )


    print(

        f"Source epoch: "
        f"{metadata.get('source_epoch')}"

    )


    print(

        f"Classes: "
        f"{metadata.get('classes')}"

    )


    print(

        f"Input channels: "
        f"{metadata['input']['channels']}"

    )


    print(

        f"Input size: "
        f"{metadata['input']['width']}x"
        f"{metadata['input']['height']}"

    )


    print(

        f"Device: "
        f"{DEVICE}"

    )


    # --------------------------------------------------------
    # CREATE TEST INPUT
    # --------------------------------------------------------

    print("\n" + "-" * 70)

    print(
        "TESTING MODEL INFERENCE"
    )

    print("-" * 70)


    input_channels = (

        metadata["input"]["channels"]

    )


    height = (

        metadata["input"]["height"]

    )


    width = (

        metadata["input"]["width"]

    )


    dummy_input = torch.randn(

        1,

        input_channels,

        height,

        width

    ).to(

        DEVICE

    )


    # --------------------------------------------------------
    # RUN INFERENCE
    # --------------------------------------------------------

    with torch.no_grad():

        output = model(

            dummy_input

        )


        probabilities = torch.softmax(

            output,

            dim=1

        )


        predicted_class = torch.argmax(

            probabilities,

            dim=1

        ).item()


    confidence = (

        probabilities[
            0,
            predicted_class
        ].item()

    )


    # --------------------------------------------------------
    # RESULTS
    # --------------------------------------------------------

    print(

        f"\nTest input shape: "
        f"{dummy_input.shape}"

    )


    print(

        f"Model output shape: "
        f"{output.shape}"

    )


    print(

        f"\nPredicted class index: "
        f"{predicted_class}"

    )


    classes = metadata.get(

        "classes",

        []

    )


    if predicted_class < len(classes):

        print(

            f"Predicted class: "
            f"{classes[predicted_class]}"

        )


    print(

        f"Confidence: "
        f"{confidence * 100:.2f}%"

    )


    # --------------------------------------------------------
    # VALIDATION CHECKS
    # --------------------------------------------------------

    print("\n" + "-" * 70)

    print(
        "VALIDATION CHECKS"
    )

    print("-" * 70)


    checks = {

        "Model file exists":

            MODEL_PATH.exists(),


        "Metadata file exists":

            METADATA_PATH.exists(),


        "Model state loaded":

            model is not None,


        "Output contains correct classes":

            output.shape[1]
            ==
            metadata["input"]["channels"] * 0 + len(classes),


        "Probabilities are valid":

            torch.allclose(

                probabilities.sum(

                    dim=1

                ),

                torch.ones(

                    probabilities.shape[0],

                    device=DEVICE

                ),

                atol=1e-5

            )

    }


    all_successful = True


    for name, result in checks.items():

        status = (

            "PASS"

            if result

            else

            "FAIL"

        )


        print(

            f"{name:<40} {status}"

        )


        if not result:

            all_successful = False


    # --------------------------------------------------------
    # FINAL RESULT
    # --------------------------------------------------------

    print("\n" + "=" * 70)


    if all_successful:

        print(

            "PRODUCTION MODEL VERIFIED SUCCESSFULLY"

        )

    else:

        print(

            "PRODUCTION MODEL VERIFICATION FAILED"

        )


    print("=" * 70)


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":

    verify_model()