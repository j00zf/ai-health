import torch

from src.model import FacialStressModel
from src.config import DEVICE


# Create model
model = FacialStressModel(
    num_classes=2
)


# Move model to device
model = model.to(
    DEVICE
)


# Create dummy image batch
dummy_input = torch.randn(

    4,
    3,
    224,
    224

).to(DEVICE)


# Run prediction
output = model(
    dummy_input
)


print("Device:")

print(DEVICE)


print("\nInput shape:")

print(dummy_input.shape)


print("\nOutput shape:")

print(output.shape)


print("\nModel output:")

print(output)