from pathlib import Path
import json

import torch

from src.config import (
    DEVICE,
    MODEL_PATH,
    CLASS_NAMES
)

from src.model import FacialStressModel


# ============================================================
# PATHS
# ============================================================

EXPORT_DIR = Path("models")

PRODUCTION_MODEL_PATH = (
    EXPORT_DIR
    / "production_model.pt"
)

METADATA_PATH = (
    EXPORT_DIR
    / "production_model_metadata.json"
)


# ============================================================
# LOAD TRAINED MODEL
# ============================================================

def load_model():

    if not MODEL_PATH.exists():

        raise FileNotFoundError(

            f"\nTrained model not found:\n"
            f"{MODEL_PATH}"

        )


    print("\nLoading trained model...")


    checkpoint = torch.load(

        MODEL_PATH,

        map_location=DEVICE,

        weights_only=False

    )


    model = FacialStressModel(

        num_classes=len(CLASS_NAMES)

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
# EXPORT MODEL
# ============================================================

def export_model():

    print("=" * 70)

    print(
        "FACIAL STRESS MODEL EXPORT"
    )

    print("=" * 70)


    # --------------------------------------------------------
    # CREATE EXPORT DIRECTORY
    # --------------------------------------------------------

    EXPORT_DIR.mkdir(

        parents=True,

        exist_ok=True

    )


    # --------------------------------------------------------
    # LOAD MODEL
    # --------------------------------------------------------

    model, checkpoint = load_model()


    # --------------------------------------------------------
    # SAVE PRODUCTION MODEL
    # --------------------------------------------------------

    production_checkpoint = {

        "model_state_dict":

            model.state_dict(),


        "num_classes":

            len(CLASS_NAMES),


        "class_names":

            CLASS_NAMES,


        "image_size":

            [48, 48],


        "input_channels":

            1,


        "normalization": {

            "mean": [0.5],

            "std": [0.5]

        },


        "source_epoch":

            checkpoint.get(
                "epoch"
            ),


        "model_version":

            "V1"


    }


    torch.save(

        production_checkpoint,

        PRODUCTION_MODEL_PATH

    )


    # --------------------------------------------------------
    # CREATE METADATA
    # --------------------------------------------------------

    metadata = {

        "model_name":

            "Facial Stress CNN",


        "model_version":

            "V1",


        "selected_as":

            "production model",


        "source_epoch":

            checkpoint.get(
                "epoch"
            ),


        "input": {

            "channels":

                1,


            "width":

                48,


            "height":

                48

        },


        "classes":

            list(CLASS_NAMES),


        "normalization": {

            "mean":

                [0.5],


            "std":

                [0.5]

        },


        "framework":

            "PyTorch"


    }


    with open(

        METADATA_PATH,

        "w",

        encoding="utf-8"

    ) as file:

        json.dump(

            metadata,

            file,

            indent=4

        )


    # --------------------------------------------------------
    # RESULTS
    # --------------------------------------------------------

    print("\nProduction model exported successfully.")


    print(

        f"\nModel file:\n"
        f"{PRODUCTION_MODEL_PATH}"

    )


    print(

        f"\nMetadata file:\n"
        f"{METADATA_PATH}"

    )


    print(

        f"\nModel version: "
        f"{metadata['model_version']}"

    )


    print(

        f"Source epoch: "
        f"{metadata['source_epoch']}"

    )


    print(

        f"Classes: "
        f"{metadata['classes']}"

    )


    print(

        f"Input size: "
        f"{metadata['input']['width']}x"
        f"{metadata['input']['height']}"

    )


    print("\n" + "=" * 70)

    print(
        "EXPORT COMPLETE"
    )

    print("=" * 70)


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":

    export_model()