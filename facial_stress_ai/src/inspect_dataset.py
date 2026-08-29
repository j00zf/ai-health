from pathlib import Path
import pandas as pd


BASE_DIR = Path(__file__).resolve().parent.parent

RAW_DATA_DIR = BASE_DIR / "data" / "raw"


def find_dataset_file():

    files = list(
        RAW_DATA_DIR.rglob(
            "facial_expression.csv"
        )
    )

    if not files:
        raise FileNotFoundError(
            f"facial_expression.csv not found in: {RAW_DATA_DIR}"
        )

    return files[0]


def main():

    data_file = find_dataset_file()

    print("Dataset found:")
    print(data_file)

    df = pd.read_csv(data_file)

    print("\nDataset Shape:")
    print(df.shape)

    print("\nColumns:")
    print(list(df.columns))

    print("\nFirst 5 rows:")
    print(df.head())

    print("\nData Types:")
    print(df.dtypes)

    print("\nMissing Values:")
    print(df.isnull().sum())

    print("\nDataset Information:")
    df.info()


if __name__ == "__main__":
    main()