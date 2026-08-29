from pathlib import Path

import numpy as np
import pandas as pd


# ==========================================
# CONFIGURATION
# ==========================================

BASE_DIR = Path(__file__).resolve().parent.parent

RAW_DATA_DIR = BASE_DIR / "data" / "raw"

CLEANED_DATA_DIR = BASE_DIR / "data" / "cleaned"

CLEANED_DATA_DIR.mkdir(
    parents=True,
    exist_ok=True
)


# ==========================================
# FIND DATASET
# ==========================================

def find_dataset_file():

    files = list(
        RAW_DATA_DIR.rglob(
            "facial_expression.csv"
        )
    )

    if not files:

        raise FileNotFoundError(
            "facial_expression.csv not found"
        )

    return files[0]


# ==========================================
# VALIDATE PIXELS
# ==========================================

def validate_pixels(pixel_string):

    try:

        pixels = np.fromstring(
            str(pixel_string),
            dtype=np.float32,
            sep=" "
        )

        # Must contain exactly 48 × 48 pixels
        if len(pixels) != 2304:
            return False

        # Pixel values must be valid
        if np.any(pixels < 0):
            return False

        if np.any(pixels > 255):
            return False

        # Check for invalid numeric values
        if np.isnan(pixels).any():
            return False

        return True

    except Exception:

        return False


# ==========================================
# MAIN CLEANING PIPELINE
# ==========================================

def main():

    print("=" * 60)
    print("FACIAL DATA CLEANING")
    print("=" * 60)


    # --------------------------------------
    # FIND DATA
    # --------------------------------------

    data_file = find_dataset_file()

    print("\nInput file:")
    print(data_file)


    # --------------------------------------
    # LOAD DATA
    # --------------------------------------

    df = pd.read_csv(
        data_file
    )

    original_count = len(df)

    print(
        f"\nOriginal samples: {original_count}"
    )


    # --------------------------------------
    # REMOVE MISSING VALUES
    # --------------------------------------

    df = df.dropna(
        subset=[
            "emotion",
            "pixels"
        ]
    ).copy()

    print(
        f"After removing missing values: "
        f"{len(df)}"
    )


    # --------------------------------------
    # VALIDATE LABELS
    # --------------------------------------

    valid_labels = [0, 1]

    df = df[
        df["emotion"].isin(
            valid_labels
        )
    ].copy()

    print(
        f"After validating labels: "
        f"{len(df)}"
    )


    # --------------------------------------
    # VALIDATE PIXELS
    # --------------------------------------

    print(
        "\nValidating pixel data..."
    )

    df["is_valid"] = df[
        "pixels"
    ].apply(
        validate_pixels
    )

    invalid_count = (
        ~df["is_valid"]
    ).sum()

    print(
        f"Invalid samples found: "
        f"{invalid_count}"
    )


    df = df[
        df["is_valid"]
    ].copy()


    # --------------------------------------
    # CLEAN DATA
    # --------------------------------------

    df = df[
        [
            "emotion",
            "pixels"
        ]
    ]


    # --------------------------------------
    # RESET INDEX
    # --------------------------------------

    df = df.reset_index(
        drop=True
    )


    # --------------------------------------
    # SAVE
    # --------------------------------------

    output_file = (
        CLEANED_DATA_DIR
        / "facial_expression_cleaned.csv"
    )

    df.to_csv(
        output_file,
        index=False
    )


    # --------------------------------------
    # SUMMARY
    # --------------------------------------

    print("\n" + "=" * 60)
    print("CLEANING SUMMARY")
    print("=" * 60)

    print(
        f"\nOriginal samples: {original_count}"
    )

    print(
        f"Final samples:    {len(df)}"
    )

    print(
        f"Removed samples:  "
        f"{original_count - len(df)}"
    )


    print("\nClass distribution:")

    print(
        df["emotion"]
        .value_counts()
        .sort_index()
    )


    print("\nSaved cleaned dataset:")

    print(output_file)


if __name__ == "__main__":

    main()