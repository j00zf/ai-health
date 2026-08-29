from pathlib import Path
import torch


# ==========================================
# PROJECT PATHS
# ==========================================

BASE_DIR = Path(__file__).resolve().parent.parent

DATA_DIR = BASE_DIR / "data"

RAW_DATA_DIR = DATA_DIR / "raw"

CLEANED_DATA_DIR = DATA_DIR / "cleaned"

PROCESSED_DATA_DIR = DATA_DIR / "processed"

MODELS_DIR = BASE_DIR / "models"

OUTPUTS_DIR = BASE_DIR / "outputs"


# ==========================================
# CREATE DIRECTORIES
# ==========================================

MODELS_DIR.mkdir(
    parents=True,
    exist_ok=True
)

OUTPUTS_DIR.mkdir(
    parents=True,
    exist_ok=True
)


# ==========================================
# MODEL CONFIGURATION
# ==========================================

IMAGE_SIZE = 224

NUM_CLASSES = 2

CLASS_NAMES = [
    "Non-Stress",
    "Stress"
]


# ==========================================
# TRAINING CONFIGURATION
# ==========================================

BATCH_SIZE = 32

NUM_EPOCHS = 20

LEARNING_RATE = 0.0003

WEIGHT_DECAY = 1e-4

NUM_WORKERS = 0


# ==========================================
# DEVICE
# ==========================================

DEVICE = (
    torch.device("cuda")
    if torch.cuda.is_available()
    else torch.device("cpu")
)


# ==========================================
# MODEL FILE
# ==========================================

MODEL_PATH = (
    MODELS_DIR /
    "facial_stress_model.pth"
)