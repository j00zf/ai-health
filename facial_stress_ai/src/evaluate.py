import numpy as np
import torch

from torch.utils.data import (
    DataLoader,
    Subset
)

from sklearn.metrics import (
    accuracy_score,
    precision_recall_fscore_support,
    classification_report,
    confusion_matrix
)

from src.config import (
    DEVICE,
    BATCH_SIZE,
    NUM_WORKERS,
    RANDOM_SEED,
    MODEL_PATH,
    CLASS_NAMES
)

from src.dataset import (
    FacialStressDataset,
    load_cleaned_dataframe,
    EVAL_TRANSFORM
)

from src.model import (
    FacialStressModel
)

from src.train import (
    create_splits,
    set_seed
)


# ============================================================
# LOAD TRAINED MODEL
# ============================================================

def load_trained_model():

    if not MODEL_PATH.exists():

        raise FileNotFoundError(

            f"\nModel not found:\n{MODEL_PATH}"

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
# EVALUATE MODEL
# ============================================================

def evaluate_model(model, loader):

    all_predictions = []

    all_labels = []

    all_probabilities = []


    with torch.no_grad():

        for images, labels in loader:


            images = images.to(

                DEVICE

            )


            outputs = model(

                images

            )


            probabilities = torch.softmax(

                outputs,

                dim=1

            )


            predictions = torch.argmax(

                probabilities,

                dim=1

            )


            all_predictions.extend(

                predictions.cpu().numpy()

            )


            all_labels.extend(

                labels.numpy()

            )


            all_probabilities.extend(

                probabilities.cpu().numpy()

            )


    return (

        np.array(all_labels),

        np.array(all_predictions),

        np.array(all_probabilities)

    )


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 70)

    print(
        "FACIAL STRESS MODEL EVALUATION"
    )

    print("=" * 70)


    # --------------------------------------------------------
    # SET SAME RANDOM SEED AS TRAINING
    # --------------------------------------------------------

    set_seed(

        RANDOM_SEED

    )


    # --------------------------------------------------------
    # LOAD DATA
    # --------------------------------------------------------

    df = load_cleaned_dataframe()


    print(

        f"\nTotal dataset samples: {len(df)}"

    )


    # --------------------------------------------------------
    # RECREATE SAME DATA SPLITS
    # --------------------------------------------------------

    (

        train_indices,

        val_indices,

        test_indices

    ) = create_splits(

        df

    )


    print("\nDataset splits:")

    print(

        f"Train:      {len(train_indices)}"

    )

    print(

        f"Validation: {len(val_indices)}"

    )

    print(

        f"Test:       {len(test_indices)}"

    )


    # --------------------------------------------------------
    # CREATE EVALUATION DATASET
    # --------------------------------------------------------

    eval_dataset = FacialStressDataset(

        dataframe=df,

        transform=EVAL_TRANSFORM

    )


    test_subset = Subset(

        eval_dataset,

        test_indices

    )


    test_loader = DataLoader(

        test_subset,

        batch_size=BATCH_SIZE,

        shuffle=False,

        num_workers=NUM_WORKERS

    )


    # --------------------------------------------------------
    # LOAD MODEL
    # --------------------------------------------------------

    model, checkpoint = load_trained_model()


    print(

        f"\nUsing device: {DEVICE}"

    )


    print(

        f"Best model epoch: "
        f"{checkpoint.get('epoch')}"

    )


    # --------------------------------------------------------
    # RUN PREDICTIONS
    # --------------------------------------------------------

    y_true, y_pred, probabilities = evaluate_model(

        model,

        test_loader

    )


    # --------------------------------------------------------
    # CALCULATE METRICS
    # --------------------------------------------------------

    accuracy = accuracy_score(

        y_true,

        y_pred

    )


    precision, recall, f1, support = (

        precision_recall_fscore_support(

            y_true,

            y_pred,

            labels=[0, 1],

            zero_division=0

        )

    )


    cm = confusion_matrix(

        y_true,

        y_pred,

        labels=[0, 1]

    )


    # --------------------------------------------------------
    # PRINT RESULTS
    # --------------------------------------------------------

    print("\n" + "=" * 70)

    print(
        "OVERALL RESULTS"
    )

    print("=" * 70)


    print(

        f"\nTest Accuracy: "
        f"{accuracy * 100:.2f}%"

    )


    print(

        f"\nTotal Test Samples: "
        f"{len(y_true)}"

    )


    # --------------------------------------------------------
    # PER CLASS METRICS
    # --------------------------------------------------------

    print("\n" + "=" * 70)

    print(
        "PER-CLASS METRICS"
    )

    print("=" * 70)


    for index, class_name in enumerate(CLASS_NAMES):


        print(

            f"\n{class_name}"

        )


        print(

            f"Precision: "
            f"{precision[index]:.4f}"

        )


        print(

            f"Recall:    "
            f"{recall[index]:.4f}"

        )


        print(

            f"F1 Score:  "
            f"{f1[index]:.4f}"

        )


        print(

            f"Support:   "
            f"{support[index]}"

        )


    # --------------------------------------------------------
    # CONFUSION MATRIX
    # --------------------------------------------------------

    print("\n" + "=" * 70)

    print(
        "CONFUSION MATRIX"
    )

    print("=" * 70)


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

        f"Actual 0       "
        f"{cm[0][0]:>5}     "
        f"{cm[0][1]:>5}"

    )


    print(

        f"Actual 1       "
        f"{cm[1][0]:>5}     "
        f"{cm[1][1]:>5}"

    )


    # --------------------------------------------------------
    # CLASSIFICATION REPORT
    # --------------------------------------------------------

    print("\n" + "=" * 70)

    print(
        "CLASSIFICATION REPORT"
    )

    print("=" * 70)


    print(

        classification_report(

            y_true,

            y_pred,

            labels=[0, 1],

            target_names=CLASS_NAMES,

            zero_division=0

        )

    )


    # --------------------------------------------------------
    # INDIVIDUAL PREDICTIONS
    # --------------------------------------------------------

    print("\n" + "=" * 70)

    print(
        "INDIVIDUAL TEST PREDICTIONS"
    )

    print("=" * 70)


    for index in range(

        len(y_true)

    ):


        predicted_probability = (

            probabilities[index][
                y_pred[index]
            ]

        )


        correct = (

            y_true[index]
            ==
            y_pred[index]

        )


        status = (

            "CORRECT"
            if correct
            else "WRONG"

        )


        print(

            f"\nSample {index + 1}"

        )


        print(

            f"Actual:    "
            f"{CLASS_NAMES[y_true[index]]}"

        )


        print(

            f"Predicted: "
            f"{CLASS_NAMES[y_pred[index]]}"

        )


        print(

            f"Confidence: "
            f"{predicted_probability * 100:.2f}%"

        )


        print(

            f"Status: {status}"

        )


    # --------------------------------------------------------
    # COMPLETE
    # --------------------------------------------------------

    print("\n" + "=" * 70)

    print(
        "EVALUATION COMPLETE"
    )

    print("=" * 70)


if __name__ == "__main__":

    main()