from pathlib import Path

import numpy as np
import pandas as pd


RAW_FILE = (
    "../data/raw/cardio_train.csv"
)

OUTPUT_FILE = (
    "../data/processed/"
    "cardio_v1_clean.csv"
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
        sep=";"
    )

    print(
        f"Original records: "
        f"{len(df)}"
    )

    # =========================================================
    # REMOVE IDENTIFIER
    # =========================================================

    df = df.drop(
        columns=["id"],
        errors="ignore",
    )

    # =========================================================
    # AGE
    # =========================================================

    # Dataset stores age in days.
    df["age_years"] = (
        df["age"] / 365.25
    )

    df["age_years"] = (
        df["age_years"]
        .round(1)
    )

    df = df.drop(
        columns=["age"]
    )

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
    # BASIC RANGE FILTERS
    # =========================================================

    df = df[
        df["age_years"].between(
            18,
            100,
        )
    ]

    df = df[
        df["height"].between(
            120,
            220,
        )
    ]

    df = df[
        df["weight"].between(
            30,
            250,
        )
    ]

    df = df[
        df["bmi"].between(
            10,
            70,
        )
    ]

    # =========================================================
    # BINARY FEATURES
    # =========================================================

    # Dataset:
    # gender: 1 = female, 2 = male
    #
    # Convert to:
    # sex: 0 = female, 1 = male

    df["sex"] = (
        df["gender"] == 2
    ).astype(int)

    df = df.drop(
        columns=["gender"]
    )

    # =========================================================
    # KEEP ONLY V1 FEATURES
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
        "cardio",
    ]

    df = df[
        columns
    ]

    # =========================================================
    # MISSING VALUES
    # =========================================================

    print(
        "\nMissing values:"
    )

    print(
        df.isnull().sum()
    )

    df = df.dropna()

    # =========================================================
    # DUPLICATES
    # =========================================================

    before = len(df)

    df = df.drop_duplicates()

    print(
        f"\nDuplicates removed: "
        f"{before - len(df)}"
    )

    # =========================================================
    # SAVE
    # =========================================================

    df.to_csv(
        OUTPUT_FILE,
        index=False,
    )

    print(
        f"\nClean records: "
        f"{len(df)}"
    )

    print(
        f"Saved to: "
        f"{OUTPUT_FILE}"
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