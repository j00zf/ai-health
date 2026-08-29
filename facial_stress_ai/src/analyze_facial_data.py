from pathlib import Path
import pandas as pd
import numpy as np


# ==========================================
# PROJECT PATH
# ==========================================

BASE_DIR = Path(__file__).resolve().parent.parent

RAW_DATA_DIR = BASE_DIR / "data" / "raw"


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
# MAIN
# ==========================================

def main():

    data_file = find_dataset_file()

    df = pd.read_csv(data_file)

    print("=" * 60)
    print("FACIAL DATASET ANALYSIS")
    print("=" * 60)


    # --------------------------------------
    # LABEL ANALYSIS
    # --------------------------------------

    print("\nEMOTION LABEL COUNTS:")
    print(
        df["emotion"].value_counts().sort_index()
    )


    print("\nUNIQUE LABELS:")
    print(
        sorted(df["emotion"].unique())
    )


    # --------------------------------------
    # PIXEL ANALYSIS
    # --------------------------------------

    pixel_lengths = []

    invalid_rows = []


    for index, pixel_string in enumerate(
        df["pixels"]
    ):

        try:

            pixels = np.fromstring(
                pixel_string,
                dtype=np.uint8,
                sep=" "
            )

            pixel_lengths.append(
                len(pixels)
            )


            if len(pixels) == 0:

                invalid_rows.append(index)

        except Exception:

            invalid_rows.append(index)


    print("\nPIXEL COUNTS:")

    unique_lengths = sorted(
        set(pixel_lengths)
    )

    print(unique_lengths)


    print("\nPIXEL COUNT FREQUENCY:")

    print(
        pd.Series(pixel_lengths)
        .value_counts()
        .sort_index()
    )


    # --------------------------------------
    # IMAGE DIMENSION CHECK
    # --------------------------------------

    print("\nPOSSIBLE IMAGE DIMENSIONS:")

    for length in unique_lengths:

        side = int(
            np.sqrt(length)
        )

        if side * side == length:

            print(
                f"{length} pixels -> "
                f"{side} x {side} image"
            )

        else:

            print(
                f"{length} pixels -> "
                f"Not a square image"
            )


    # --------------------------------------
    # PIXEL VALUE CHECK
    # --------------------------------------

    all_min = []
    all_max = []


    for pixel_string in df["pixels"]:

        pixels = np.fromstring(

            pixel_string,

            dtype=np.float32,

            sep=" "
        )

        if len(pixels) > 0:

            all_min.append(
                pixels.min()
            )

            all_max.append(
                pixels.max()
            )


    print("\nPIXEL VALUE RANGE:")

    print(
        f"Minimum: {min(all_min)}"
    )

    print(
        f"Maximum: {max(all_max)}"
    )


    # --------------------------------------
    # INVALID ROWS
    # --------------------------------------

    print("\nINVALID ROWS:")

    if invalid_rows:

        print(invalid_rows)

    else:

        print("None")


    print("\n" + "=" * 60)
    print("ANALYSIS COMPLETE")
    print("=" * 60)


if __name__ == "__main__":

    main()