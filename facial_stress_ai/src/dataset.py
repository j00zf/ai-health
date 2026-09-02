from pathlib import Path

import numpy as np
import pandas as pd

import torch
from torch.utils.data import Dataset

from torchvision import transforms


# ==========================================
# PATHS
# ==========================================

BASE_DIR = Path(__file__).resolve().parent.parent

CLEANED_DATA_FILE = (
    BASE_DIR
    / "data"
    / "cleaned"
    / "facial_expression_cleaned.csv"
)


# ==========================================
# DATA AUGMENTATION
# ==========================================

TRAIN_TRANSFORM = transforms.Compose([

    transforms.ToPILImage(),

    transforms.Grayscale(
        num_output_channels=3
    ),

    transforms.RandomHorizontalFlip(
        p=0.5
    ),

    transforms.RandomRotation(
        degrees=10
    ),

    transforms.RandomAffine(
        degrees=0,
        translate=(0.05, 0.05)
    ),

    transforms.ToTensor(),

    transforms.Normalize(
        mean=[0.5, 0.5, 0.5],
        std=[0.5, 0.5, 0.5]
    )

])


# ==========================================
# VALIDATION / TEST TRANSFORM
# ==========================================

EVAL_TRANSFORM = transforms.Compose([

    transforms.ToPILImage(),

    transforms.Grayscale(
        num_output_channels=3
    ),

    transforms.ToTensor(),

    transforms.Normalize(
        mean=[0.5, 0.5, 0.5],
        std=[0.5, 0.5, 0.5]
    )

])


# ==========================================
# FACIAL STRESS DATASET
# ==========================================

class FacialStressDataset(Dataset):

    def __init__(
        self,
        dataframe,
        transform=None
    ):

        self.dataframe = (
            dataframe
            .reset_index(drop=True)
        )

        self.transform = transform


    def __len__(self):

        return len(
            self.dataframe
        )


    def __getitem__(
        self,
        index
    ):

        row = self.dataframe.iloc[index]


        # ----------------------------------
        # READ PIXELS
        # ----------------------------------

        pixels = np.fromstring(

            row["pixels"],

            dtype=np.float32,

            sep=" "

        )


        # ----------------------------------
        # RESHAPE
        # ----------------------------------

        image = pixels.reshape(
            48,
            48
        ).astype(
            np.uint8
        )


        # ----------------------------------
        # APPLY TRANSFORM
        # ----------------------------------

        if self.transform:

            image = self.transform(
                image
            )

        else:

            image = torch.tensor(
                image,
                dtype=torch.float32
            ).unsqueeze(0)

            image = image / 255.0


        # ----------------------------------
        # LABEL
        # ----------------------------------

        label = int(
            row["emotion"]
        )

        label = torch.tensor(
            label,
            dtype=torch.long
        )


        return image, label


# ==========================================
# LOAD DATAFRAME
# ==========================================

def load_cleaned_dataframe():

    if not CLEANED_DATA_FILE.exists():

        raise FileNotFoundError(

            f"Cleaned dataset not found:\n"
            f"{CLEANED_DATA_FILE}"

        )


    return pd.read_csv(
        CLEANED_DATA_FILE
    )