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
# DATA CONFIGURATION
# ==========================================

IMAGE_SIZE = 48

NUM_CLASSES = 2

CLASS_NAMES = [
    "Non-Stress",
    "Stress"
]


# ==========================================
# TRAINING CONFIGURATION
# ==========================================

BATCH_SIZE = 8

NUM_EPOCHS = 100

LEARNING_RATE = 0.001

WEIGHT_DECAY = 1e-4

NUM_WORKERS = 0

RANDOM_SEED = 42


# ==========================================
# EARLY STOPPING
# ==========================================

EARLY_STOPPING_PATIENCE = 15


# ==========================================
# DEVICE
# ==========================================

DEVICE = (
    torch.device("cuda")
    if torch.cuda.is_available()
    else torch.device("cpu")
)


# ==========================================
# MODEL PATH
# ==========================================

MODEL_PATH = (
    MODELS_DIR
    / "facial_stress_model.pth"
)