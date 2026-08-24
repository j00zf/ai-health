from pathlib import Path

import numpy as np
import pandas as pd


RAW_FILE = "../data/raw/cardio_train.csv"

OUTPUT_FILE = (
    "../data/processed/"
    "cardio_clean_common.csv"
)


def main():

    Path(
        "../data/processed"
    ).mkdir(
        parents=True,
        exist_ok=True,
    )

    df = pd.read_csv(
        RAW_FILE,
        sep=";",
    )

    print("=" * 70)
    print("PULSE AI — COMMON DATA PREPROCESSING")
    print("=" * 70)

    print(
        f"Original records: {len(df)}"
    )

    # =========================================================
    # REMOVE ONLY THE IDENTIFIER
    # =========================================================

    df = df.drop(
        columns=["id"],
        errors="ignore",
    )

    # =========================================================
    # AGE
    # =========================================================

    df["age_years"] = (
        df["age"] / 365.25
    )

    # =========================================================
    # SEX
    # =========================================================

    # Original:
    # 1 = female
    # 2 = male

    df["sex"] = (
        df["gender"] == 2
    ).astype(int)

    # =========================================================
    # BMI
    # =========================================================

    height_m = (
        df["height"] / 100
    )

    df["bmi"] = (
        df["weight"] /
        (height_m ** 2)
    )

    # =========================================================
    # BASIC VALIDATION
    # =========================================================

    df.loc[
        ~df["age_years"].between(
            18,
            100,
        ),
        "age_years",
    ] = np.nan

    df.loc[
        ~df["height"].between(
            120,
            220,
        ),
        "height",
    ] = np.nan

    df.loc[
        ~df["weight"].between(
            30,
            250,
        ),
        "weight",
    ] = np.nan

    df.loc[
        ~df["bmi"].between(
            10,
            70,
        ),
        "bmi",
    ] = np.nan

    # =========================================================
    # BLOOD PRESSURE
    # =========================================================

    # We will use these in Advanced.
    #
    # We intentionally DO NOT use glucose.

    df.loc[
        ~df["ap_hi"].between(
            70,
            250,
        ),
        "ap_hi",
    ] = np.nan

    df.loc[
        ~df["ap_lo"].between(
            40,
            150,
        ),
        "ap_lo",
    ] = np.nan

    # =========================================================
    # CHOLESTEROL
    # =========================================================

    df.loc[
        ~df["cholesterol"].isin(
            [1, 2, 3]
        ),
        "cholesterol",
    ] = np.nan

    # =========================================================
    # KEEP COMMON + ADVANCED FIELDS
    # =========================================================

    columns = [
        "age_years",
        "sex",
        "height",
        "weight",
        "bmi",

        "smoke",
        "alco",
        "active",

        "ap_hi",
        "ap_lo",
        "cholesterol",

        "cardio",
    ]

    df = df[
        columns
    ]

    # =========================================================
    # MISSING DATA REPORT
    # =========================================================

    print("\nMissing values:")

    print(
        df.isnull().sum()
    )

    # =========================================================
    # SAVE
    # =========================================================

    df.to_csv(
        OUTPUT_FILE,
        index=False,
    )

    print(
        f"\nClean records: {len(df)}"
    )

    print(
        f"Saved to: {OUTPUT_FILE}"
    )

    print(
        "\nTarget distribution:"
    )

    print(
        df["cardio"]
        .value_counts()
    )


if __name__ == "__main__":
    main()