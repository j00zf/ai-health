from pathlib import Path
import kagglehub
import shutil


DATASET = (
    "sulianova/"
    "cardiovascular-disease-dataset"
)

RAW_DIR = Path("../data/raw")


def main():

    RAW_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    print("=" * 70)
    print("PULSE AI — DATASET DOWNLOAD")
    print("=" * 70)

    path = kagglehub.dataset_download(
        DATASET
    )

    print(f"\nDownloaded dataset to:")
    print(path)

    source = Path(path)

    csv_files = list(
        source.rglob("*.csv")
    )

    if not csv_files:
        raise FileNotFoundError(
            "No CSV file found."
        )

    print("\nCSV files found:")

    for file in csv_files:
        print(
            f" - {file}"
        )

    # The dataset normally contains cardio_train.csv
    selected = None

    for file in csv_files:

        if "cardio" in file.name.lower():
            selected = file
            break

    if selected is None:
        selected = csv_files[0]

    destination = (
        RAW_DIR /
        "cardio_train.csv"
    )

    shutil.copy2(
        selected,
        destination,
    )

    print(
        f"\nCopied dataset to:"
        f"\n{destination}"
    )


if __name__ == "__main__":
    main()