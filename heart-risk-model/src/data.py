from __future__ import annotations

import pandas as pd

from .config import DATA_PATH, FEATURES, TARGET


def load_dataset(path=DATA_PATH) -> pd.DataFrame:
    path = str(path)
    df = pd.read_csv(path)

    required = set(FEATURES + [TARGET])
    missing = sorted(required - set(df.columns))
    if missing:
        raise ValueError(
            "Dataset is missing required columns: " + ", ".join(missing)
        )

    return df[FEATURES + [TARGET]].copy()


def clean_basic(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # Convert expected numeric columns where possible.
    for col in df.columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    # Remove invalid target rows.
    df = df[df[TARGET].isin([0, 1])].copy()

    # Data-quality checks. These are not medical diagnostic thresholds;
    # they only prevent obviously corrupted records from entering training.
    bounds = {
        "age": (18, 120),
        "cigsPerDay": (0, 150),
        "totChol": (80, 1000),
        "sysBP": (60, 300),
        "diaBP": (30, 200),
        "BMI": (10, 100),
        "heartRate": (25, 250),
        "glucose": (20, 1000),
    }

    for col, (low, high) in bounds.items():
        if col in df:
            df.loc[(df[col] < low) | (df[col] > high), col] = pd.NA

    return df.reset_index(drop=True)
