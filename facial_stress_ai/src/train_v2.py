import random
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn

from torch.optim import AdamW
from torch.optim.lr_scheduler import ReduceLROnPlateau

from torch.utils.data import (
    DataLoader,
    Subset
)

from sklearn.model_selection import (
    train_test_split
)

from src.config import (
    DEVICE,
    BATCH_SIZE,
    NUM_EPOCHS,
    LEARNING_RATE,
    WEIGHT_DECAY,
    NUM_WORKERS,
    RANDOM_SEED,
    EARLY_STOPPING_PATIENCE
)

from src.dataset import (
    FacialStressDataset,
    load_cleaned_dataframe
)

from src.augmentations import (
    TRAIN_TRANSFORM,
    EVAL_TRANSFORM
)

from src.model import (
    FacialStressModel
)


# ============================================================
# MODEL PATH
# ============================================================

MODEL_V2_PATH = Path(
    "models/facial_stress_model_v2.pth"
)

MODEL_V2_PATH.parent.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# SET RANDOM SEED
# ============================================================

def set_seed(seed):

    random.seed(seed)

    np.random.seed(seed)

    torch.manual_seed(seed)

    if torch.cuda.is_available():

        torch.cuda.manual_seed_all(
            seed
        )

        torch.backends.cudnn.deterministic = True

        torch.backends.cudnn.benchmark = False


# ============================================================
# CREATE DATA SPLITS
# ============================================================

def create_splits(df):

    indices = np.arange(
        len(df)
    )

    labels = df[
        "emotion"
    ].values


    train_indices, temp_indices = train_test_split(

        indices,

        test_size=0.20,

        stratify=labels,

        random_state=RANDOM_SEED

    )


    temp_labels = labels[
        temp_indices
    ]


    val_indices, test_indices = train_test_split(

        temp_indices,

        test_size=0.50,

        stratify=temp_labels,

        random_state=RANDOM_SEED

    )


    return (

        train_indices,

        val_indices,

        test_indices

    )


# ============================================================
# TRAIN ONE EPOCH
# ============================================================

def train_one_epoch(

    model,
    loader,
    criterion,
    optimizer

):

    model.train()


    total_loss = 0.0

    total_correct = 0

    total_samples = 0


    for images, labels in loader:


        images = images.to(
            DEVICE
        )


        labels = labels.to(
            DEVICE
        )


        optimizer.zero_grad()


        outputs = model(
            images
        )


        loss = criterion(

            outputs,

            labels

        )


        loss.backward()


        optimizer.step()


        total_loss += (

            loss.item()
            * images.size(0)

        )


        predictions = torch.argmax(

            outputs,

            dim=1

        )


        total_correct += (

            predictions == labels

        ).sum().item()


        total_samples += labels.size(0)


    average_loss = (

        total_loss
        / total_samples

    )


    accuracy = (

        total_correct
        / total_samples

    )


    return average_loss, accuracy


# ============================================================
# VALIDATE
# ============================================================

def validate(

    model,
    loader,
    criterion

):

    model.eval()


    total_loss = 0.0

    total_correct = 0

    total_samples = 0


    with torch.no_grad():


        for images, labels in loader:


            images = images.to(
                DEVICE
            )


            labels = labels.to(
                DEVICE
            )


            outputs = model(
                images
            )


            loss = criterion(

                outputs,

                labels

            )


            total_loss += (

                loss.item()
                * images.size(0)

            )


            predictions = torch.argmax(

                outputs,

                dim=1

            )


            total_correct += (

                predictions == labels

            ).sum().item()


            total_samples += labels.size(0)


    average_loss = (

        total_loss
        / total_samples

    )


    accuracy = (

        total_correct
        / total_samples

    )


    return average_loss, accuracy


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 70)

    print(
        "FACIAL STRESS MODEL V2 TRAINING"
    )

    print("=" * 70)


    # --------------------------------------------------------
    # SET SEED
    # --------------------------------------------------------

    set_seed(
        RANDOM_SEED
    )


    # --------------------------------------------------------
    # LOAD DATA
    # --------------------------------------------------------

    df = load_cleaned_dataframe()


    print(
        f"\nTotal samples: {len(df)}"
    )


    # --------------------------------------------------------
    # CREATE SPLITS
    # --------------------------------------------------------

    (

        train_indices,
        val_indices,
        test_indices

    ) = create_splits(
        df
    )


    print(
        "\nDataset splits:"
    )


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
    # CREATE DATASETS
    # --------------------------------------------------------

    print(
        "\nCreating datasets..."
    )


    # Training data gets augmentation
    train_dataset = FacialStressDataset(

        dataframe=df,

        transform=TRAIN_TRANSFORM

    )


    # Validation/test do not get augmentation
    eval_dataset = FacialStressDataset(

        dataframe=df,

        transform=EVAL_TRANSFORM

    )


    train_subset = Subset(

        train_dataset,

        train_indices

    )


    val_subset = Subset(

        eval_dataset,

        val_indices

    )


    test_subset = Subset(

        eval_dataset,

        test_indices

    )


    # --------------------------------------------------------
    # CREATE DATALOADERS
    # --------------------------------------------------------

    train_loader = DataLoader(

        train_subset,

        batch_size=BATCH_SIZE,

        shuffle=True,

        num_workers=NUM_WORKERS,

        pin_memory=torch.cuda.is_available()

    )


    val_loader = DataLoader(

        val_subset,

        batch_size=BATCH_SIZE,

        shuffle=False,

        num_workers=NUM_WORKERS,

        pin_memory=torch.cuda.is_available()

    )


    test_loader = DataLoader(

        test_subset,

        batch_size=BATCH_SIZE,

        shuffle=False,

        num_workers=NUM_WORKERS,

        pin_memory=torch.cuda.is_available()

    )


    # --------------------------------------------------------
    # CREATE MODEL
    # --------------------------------------------------------

    model = FacialStressModel(

        num_classes=2

    )


    model = model.to(
        DEVICE
    )


    print(
        f"\nUsing device: {DEVICE}"
    )


    # --------------------------------------------------------
    # CLASS WEIGHTS
    # --------------------------------------------------------

    train_labels = (

        df.iloc[
            train_indices
        ]["emotion"]
        .values

    )


    class_counts = np.bincount(

        train_labels,

        minlength=2

    )


    class_weights = (

        len(train_labels)
        /
        (
            2 * class_counts
        )

    )


    class_weights = torch.tensor(

        class_weights,

        dtype=torch.float32,

        device=DEVICE

    )


    print(
        "\nTraining class counts:"
    )

    print(
        class_counts
    )


    print(
        "\nClass weights:"
    )

    print(
        class_weights
    )


    # --------------------------------------------------------
    # LOSS FUNCTION
    # --------------------------------------------------------

    criterion = nn.CrossEntropyLoss(

        weight=class_weights

    )


    # --------------------------------------------------------
    # OPTIMIZER
    # --------------------------------------------------------

    optimizer = AdamW(

        model.parameters(),

        lr=LEARNING_RATE,

        weight_decay=WEIGHT_DECAY

    )


    # --------------------------------------------------------
    # LEARNING RATE SCHEDULER
    # --------------------------------------------------------

    scheduler = ReduceLROnPlateau(

        optimizer,

        mode="min",

        factor=0.5,

        patience=5

    )


    # --------------------------------------------------------
    # TRAINING VARIABLES
    # --------------------------------------------------------

    best_val_loss = float(
        "inf"
    )


    patience_counter = 0


    history = {

        "train_loss": [],

        "train_accuracy": [],

        "val_loss": [],

        "val_accuracy": []

    }


    # ========================================================
    # TRAINING LOOP
    # ========================================================

    for epoch in range(

        1,

        NUM_EPOCHS + 1

    ):


        train_loss, train_accuracy = train_one_epoch(

            model,

            train_loader,

            criterion,

            optimizer

        )


        val_loss, val_accuracy = validate(

            model,

            val_loader,

            criterion

        )


        scheduler.step(
            val_loss
        )


        history[
            "train_loss"
        ].append(
            train_loss
        )


        history[
            "train_accuracy"
        ].append(
            train_accuracy
        )


        history[
            "val_loss"
        ].append(
            val_loss
        )


        history[
            "val_accuracy"
        ].append(
            val_accuracy
        )


        current_lr = (

            optimizer.param_groups[0][
                "lr"
            ]

        )


        print(

            f"\nEpoch "
            f"[{epoch}/{NUM_EPOCHS}]"

        )


        print(

            f"Train Loss: "
            f"{train_loss:.4f} | "

            f"Train Accuracy: "
            f"{train_accuracy * 100:.2f}%"

        )


        print(

            f"Validation Loss: "
            f"{val_loss:.4f} | "

            f"Validation Accuracy: "
            f"{val_accuracy * 100:.2f}%"

        )


        print(

            f"Learning Rate: "
            f"{current_lr:.8f}"

        )


        # ----------------------------------------------------
        # SAVE BEST MODEL
        # ----------------------------------------------------

        if val_loss < best_val_loss:


            best_val_loss = val_loss

            patience_counter = 0


            torch.save(

                {

                    "epoch": epoch,

                    "model_state_dict":

                        model.state_dict(),

                    "optimizer_state_dict":

                        optimizer.state_dict(),

                    "validation_loss":

                        val_loss,

                    "validation_accuracy":

                        val_accuracy,

                    "test_indices":

                        test_indices.tolist(),

                    "val_indices":

                        val_indices.tolist(),

                    "train_indices":

                        train_indices.tolist(),

                    "history":

                        history

                },

                MODEL_V2_PATH

            )


            print(
                "✓ Best V2 model saved"
            )


        else:


            patience_counter += 1


            print(

                f"No improvement: "

                f"{patience_counter}/"

                f"{EARLY_STOPPING_PATIENCE}"

            )


        # ----------------------------------------------------
        # EARLY STOPPING
        # ----------------------------------------------------

        if (

            patience_counter

            >=

            EARLY_STOPPING_PATIENCE

        ):


            print(
                "\nEarly stopping activated."
            )


            break


    # ========================================================
    # FINAL TEST
    # ========================================================

    print(
        "\n" + "=" * 70
    )


    print(
        "LOADING BEST V2 MODEL FOR TESTING"
    )


    print(
        "=" * 70
    )


    checkpoint = torch.load(

        MODEL_V2_PATH,

        map_location=DEVICE,

        weights_only=False

    )


    model.load_state_dict(

        checkpoint[
            "model_state_dict"
        ]

    )


    test_loss, test_accuracy = validate(

        model,

        test_loader,

        criterion

    )


    print(

        f"\nBest Epoch: "

        f"{checkpoint['epoch']}"

    )


    print(

        f"Test Loss: "

        f"{test_loss:.4f}"

    )


    print(

        f"Test Accuracy: "

        f"{test_accuracy * 100:.2f}%"

    )


    print(

        f"\nModel saved to:"

    )

    print(
        MODEL_V2_PATH
    )


    print(
        "\n" + "=" * 70
    )


    print(
        "MODEL V2 TRAINING COMPLETE"
    )


    print(
        "=" * 70
    )


if __name__ == "__main__":

    main()