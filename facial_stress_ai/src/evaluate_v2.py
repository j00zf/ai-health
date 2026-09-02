import json
from pathlib import Path

import numpy as np
import torch

from sklearn.metrics import (
    accuracy_score,
    precision_recall_fscore_support,
    classification_report,
    confusion_matrix,
)

from torch.utils.data import DataLoader, Subset

from src.config import (
    DEVICE,
    BATCH_SIZE,
    NUM_WORKERS,
)

from src.dataset import (
    FacialStressDataset,
    load_cleaned_dataframe,
)

from src.augmentations import EVAL_TRANSFORM

from src.model import FacialStressModel


# ============================================================
# PATHS
# ============================================================

MODEL_PATH = Path(
    "models/facial_stress_model_v2.pth"
)

OUTPUT_DIR = Path(
    "outputs"
)

OUTPUT_DIR.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 70)

    print(
        "FACIAL STRESS MODEL V2 EVALUATION"
    )

    print("=" * 70)


    # --------------------------------------------------------
    # LOAD CHECKPOINT
    # --------------------------------------------------------

    if not MODEL_PATH.exists():

        raise FileNotFoundError(

            f"\nModel not found:\n{MODEL_PATH}\n"

            "Please train the V2 model first:\n"

            "python -m src.train_v2"

        )


    checkpoint = torch.load(

        MODEL_PATH,

        map_location=DEVICE,

        weights_only=False

    )


    # --------------------------------------------------------
    # LOAD DATA
    # --------------------------------------------------------

    df = load_cleaned_dataframe()


    print(
        f"\nTotal dataset samples: {len(df)}"
    )


    # --------------------------------------------------------
    # LOAD TEST INDICES
    # --------------------------------------------------------

    test_indices = checkpoint.get(
        "test_indices"
    )


    if test_indices is None:

        raise ValueError(

            "Test indices were not found "

            "inside the checkpoint."

        )


    print(
        f"Test samples: {len(test_indices)}"
    )


    # --------------------------------------------------------
    # DATASET
    # --------------------------------------------------------

    dataset = FacialStressDataset(

        dataframe=df,

        transform=EVAL_TRANSFORM

    )


    test_dataset = Subset(

        dataset,

        test_indices

    )


    test_loader = DataLoader(

        test_dataset,

        batch_size=BATCH_SIZE,

        shuffle=False,

        num_workers=NUM_WORKERS,

        pin_memory=torch.cuda.is_available()

    )


    # --------------------------------------------------------
    # MODEL
    # --------------------------------------------------------

    model = FacialStressModel(
        num_classes=2
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


    print(
        f"\nUsing device: {DEVICE}"
    )


    print(
        f"Best model epoch: "

        f"{checkpoint['epoch']}"
    )


    # --------------------------------------------------------
    # PREDICTION
    # --------------------------------------------------------

    all_predictions = []

    all_labels = []

    all_confidences = []


    with torch.no_grad():

        for images, labels in test_loader:


            images = images.to(
                DEVICE
            )


            labels = labels.to(
                DEVICE
            )


            outputs = model(
                images
            )


            probabilities = torch.softmax(

                outputs,

                dim=1

            )


            confidences, predictions = torch.max(

                probabilities,

                dim=1

            )


            all_predictions.extend(

                predictions.cpu().numpy()

            )


            all_labels.extend(

                labels.cpu().numpy()

            )


            all_confidences.extend(

                confidences.cpu().numpy()

            )


    # --------------------------------------------------------
    # CONVERT TO NUMPY
    # --------------------------------------------------------

    all_predictions = np.array(
        all_predictions
    )


    all_labels = np.array(
        all_labels
    )


    all_confidences = np.array(
        all_confidences
    )


    # --------------------------------------------------------
    # METRICS
    # --------------------------------------------------------

    accuracy = accuracy_score(

        all_labels,

        all_predictions

    )


    precision, recall, f1, support = (

        precision_recall_fscore_support(

            all_labels,

            all_predictions,

            labels=[0, 1],

            zero_division=0

        )

    )


    cm = confusion_matrix(

        all_labels,

        all_predictions,

        labels=[0, 1]

    )


    print(
        "\n" + "=" * 70
    )


    print(
        "OVERALL RESULTS"
    )


    print(
        "=" * 70
    )


    print(
        f"\nTest Accuracy: "

        f"{accuracy * 100:.2f}%"

    )


    print(
        f"\nTotal Test Samples: "

        f"{len(all_labels)}"

    )


    # --------------------------------------------------------
    # PER CLASS METRICS
    # --------------------------------------------------------

    print(
        "\n" + "=" * 70
    )


    print(
        "PER-CLASS METRICS"
    )


    print(
        "=" * 70
    )


    for class_id in [0, 1]:

        print(
            f"\nClass {class_id}"
        )


        print(
            f"Precision: "

            f"{precision[class_id]:.4f}"
        )


        print(
            f"Recall:    "

            f"{recall[class_id]:.4f}"
        )


        print(
            f"F1 Score:  "

            f"{f1[class_id]:.4f}"
        )


        print(
            f"Support:   "

            f"{support[class_id]}"
        )


    # --------------------------------------------------------
    # CONFUSION MATRIX
    # --------------------------------------------------------

    print(
        "\n" + "=" * 70
    )


    print(
        "CONFUSION MATRIX"
    )


    print(
        "=" * 70
    )


    print(
        "\nRows = Actual class"
    )


    print(
        "Columns = Predicted class\n"
    )


    print(
        "                 Pred 0    Pred 1"
    )


    print(

        f"Actual 0"

        f"           {cm[0][0]}"

        f"         {cm[0][1]}"

    )


    print(

        f"Actual 1"

        f"           {cm[1][0]}"

        f"         {cm[1][1]}"

    )


    # --------------------------------------------------------
    # CLASSIFICATION REPORT
    # --------------------------------------------------------

    print(
        "\n" + "=" * 70
    )


    print(
        "CLASSIFICATION REPORT"
    )


    print(
        "=" * 70
    )


    print(

        classification_report(

            all_labels,

            all_predictions,

            labels=[0, 1],

            target_names=[

                "Non-Stress",

                "Stress"

            ],

            zero_division=0

        )

    )


    # --------------------------------------------------------
    # INDIVIDUAL RESULTS
    # --------------------------------------------------------

    print(
        "\n" + "=" * 70
    )


    print(
        "INDIVIDUAL TEST PREDICTIONS"
    )


    print(
        "=" * 70
    )


    for i in range(

        len(all_labels)

    ):


        actual = int(
            all_labels[i]
        )


        predicted = int(
            all_predictions[i]
        )


        confidence = float(
            all_confidences[i]
        )


        status = (

            "CORRECT"

            if actual == predicted

            else "WRONG"

        )


        print(
            f"\nSample {i + 1}"
        )


        print(
            f"Actual:    "

            f"Class {actual}"
        )


        print(
            f"Predicted: "

            f"Class {predicted}"
        )


        print(
            f"Confidence: "

            f"{confidence * 100:.2f}%"
        )


        print(
            f"Status: {status}"
        )


    # --------------------------------------------------------
    # SAVE RESULTS
    # --------------------------------------------------------

    results = {

        "model_version": "V2",

        "best_epoch":

            int(
                checkpoint["epoch"]
            ),

        "test_accuracy":

            float(accuracy),

        "test_samples":

            int(
                len(all_labels)
            ),

        "class_0": {

            "precision":

                float(precision[0]),

            "recall":

                float(recall[0]),

            "f1":

                float(f1[0]),

            "support":

                int(support[0])

        },

        "class_1": {

            "precision":

                float(precision[1]),

            "recall":

                float(recall[1]),

            "f1":

                float(f1[1]),

            "support":

                int(support[1])

        },

        "confusion_matrix":

            cm.tolist()

    }


    output_file = (

        OUTPUT_DIR
        /
        "v2_results.json"

    )


    with open(

        output_file,

        "w",

        encoding="utf-8"

    ) as file:


        json.dump(

            results,

            file,

            indent=4

        )


    print(
        "\n" + "=" * 70
    )


    print(
        "RESULTS SAVED"
    )


    print(
        "=" * 70
    )


    print(
        output_file
    )


    print(
        "\nEvaluation complete."
    )


if __name__ == "__main__":

    main()