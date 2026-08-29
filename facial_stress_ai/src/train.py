import random

import numpy as np
import torch
import torch.nn as nn

from torch.optim import AdamW

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
    EARLY_STOPPING_PATIENCE,
    MODEL_PATH
)

from src.dataset import (
    FacialStressDataset,
    load_cleaned_dataframe,
    TRAIN_TRANSFORM,
    EVAL_TRANSFORM
)

from src.model import (
    FacialStressModel
)


# ==========================================
# SET RANDOM SEED
# ==========================================

def set_seed(seed):

    random.seed(seed)

    np.random.seed(seed)

    torch.manual_seed(seed)

    if torch.cuda.is_available():

        torch.cuda.manual_seed_all(
            seed
        )


# ==========================================
# CREATE DATA SPLITS
# ==========================================

def create_splits(df):

    indices = np.arange(
        len(df)
    )

    labels = df["emotion"].values


    # --------------------------------------
    # 80% TRAIN
    # 20% TEMP
    # --------------------------------------

    train_indices, temp_indices = train_test_split(

        indices,

        test_size=0.20,

        stratify=labels,

        random_state=RANDOM_SEED

    )


    # --------------------------------------
    # TEMP → VALIDATION + TEST
    # --------------------------------------

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


# ==========================================
# CALCULATE ACCURACY
# ==========================================

def calculate_accuracy(

    predictions,

    labels

):

    predicted_classes = torch.argmax(

        predictions,

        dim=1

    )


    correct = (

        predicted_classes == labels

    ).sum().item()


    total = labels.size(0)


    return correct / total


# ==========================================
# TRAIN ONE EPOCH
# ==========================================

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


        # Forward pass

        optimizer.zero_grad()

        outputs = model(
            images
        )

        loss = criterion(
            outputs,
            labels
        )


        # Backpropagation

        loss.backward()

        optimizer.step()


        # Statistics

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


        total_samples += (
            labels.size(0)
        )


    average_loss = (

        total_loss
        / total_samples

    )


    accuracy = (

        total_correct
        / total_samples

    )


    return average_loss, accuracy


# ==========================================
# VALIDATE
# ==========================================

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


            total_samples += (
                labels.size(0)
            )


    average_loss = (

        total_loss
        / total_samples

    )


    accuracy = (

        total_correct
        / total_samples

    )


    return average_loss, accuracy


# ==========================================
# MAIN
# ==========================================

def main():

    print("=" * 70)

    print(
        "FACIAL STRESS MODEL TRAINING"
    )

    print("=" * 70)


    # --------------------------------------
    # SET SEED
    # --------------------------------------

    set_seed(
        RANDOM_SEED
    )


    # --------------------------------------
    # LOAD DATA
    # --------------------------------------

    df = load_cleaned_dataframe()


    print(
        f"\nTotal samples: {len(df)}"
    )


    # --------------------------------------
    # CREATE SPLITS
    # --------------------------------------

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


    # --------------------------------------
    # CREATE DATASETS
    # --------------------------------------

    train_dataset = FacialStressDataset(

        dataframe=df,

        transform=TRAIN_TRANSFORM

    )


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


    # --------------------------------------
    # CREATE DATALOADERS
    # --------------------------------------

    train_loader = DataLoader(

        train_subset,

        batch_size=BATCH_SIZE,

        shuffle=True,

        num_workers=NUM_WORKERS

    )


    val_loader = DataLoader(

        val_subset,

        batch_size=BATCH_SIZE,

        shuffle=False,

        num_workers=NUM_WORKERS

    )


    test_loader = DataLoader(

        test_subset,

        batch_size=BATCH_SIZE,

        shuffle=False,

        num_workers=NUM_WORKERS

    )


    # --------------------------------------
    # CREATE MODEL
    # --------------------------------------

    model = FacialStressModel(
        num_classes=2
    )

    model = model.to(
        DEVICE
    )


    print(
        f"\nUsing device: {DEVICE}"
    )


    # --------------------------------------
    # LOSS FUNCTION
    # --------------------------------------

    criterion = nn.CrossEntropyLoss()


    # --------------------------------------
    # OPTIMIZER
    # --------------------------------------

    optimizer = AdamW(

        model.parameters(),

        lr=LEARNING_RATE,

        weight_decay=WEIGHT_DECAY

    )


    # --------------------------------------
    # TRAINING VARIABLES
    # --------------------------------------

    best_val_loss = float(
        "inf"
    )

    patience_counter = 0


    # ======================================
    # TRAINING LOOP
    # ======================================

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


        print(

            f"\nEpoch "
            f"[{epoch}/{NUM_EPOCHS}]"

        )


        print(

            f"Train Loss: {train_loss:.4f} | "

            f"Train Accuracy: "

            f"{train_accuracy * 100:.2f}%"

        )


        print(

            f"Validation Loss: "

            f"{val_loss:.4f} | "

            f"Validation Accuracy: "

            f"{val_accuracy * 100:.2f}%"

        )


        # ----------------------------------
        # SAVE BEST MODEL
        # ----------------------------------

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

                        val_accuracy

                },

                MODEL_PATH

            )


            print(
                "✓ Best model saved"
            )


        else:

            patience_counter += 1


            print(

                f"No improvement: "

                f"{patience_counter}/"

                f"{EARLY_STOPPING_PATIENCE}"

            )


        # ----------------------------------
        # EARLY STOPPING
        # ----------------------------------

        if (

            patience_counter

            >=

            EARLY_STOPPING_PATIENCE

        ):

            print(
                "\nEarly stopping activated."
            )

            break


    # ======================================
    # FINAL TEST
    # ======================================

    print("\n" + "=" * 70)

    print(
        "LOADING BEST MODEL FOR TESTING"
    )

    print("=" * 70)


    checkpoint = torch.load(

        MODEL_PATH,

        map_location=DEVICE

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


    print("\n" + "=" * 70)

    print(
        "TRAINING COMPLETE"
    )

    print("=" * 70)


if __name__ == "__main__":

    main()