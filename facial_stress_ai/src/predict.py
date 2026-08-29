from pathlib import Path
import sys

import torch
from PIL import Image
from torchvision import transforms

from src.config import (
    DEVICE,
    MODEL_PATH,
    CLASS_NAMES
)

from src.model import FacialStressModel


# ==========================================
# IMAGE TRANSFORM
# ==========================================

PREDICT_TRANSFORM = transforms.Compose([

    transforms.Grayscale(
        num_output_channels=1
    ),

    transforms.Resize(
        (48, 48)
    ),

    transforms.ToTensor(),

    transforms.Normalize(
        mean=[0.5],
        std=[0.5]
    )

])


# ==========================================
# LOAD MODEL
# ==========================================

def load_model():

    if not MODEL_PATH.exists():

        raise FileNotFoundError(

            f"Model not found:\n{MODEL_PATH}"

        )


    # Create model architecture
    model = FacialStressModel(
        num_classes=2
    )


    # Load checkpoint
    checkpoint = torch.load(

        MODEL_PATH,

        map_location=DEVICE,

        weights_only=False

    )


    # Load trained weights
    model.load_state_dict(

        checkpoint[
            "model_state_dict"
        ]

    )


    # Move model to device
    model = model.to(
        DEVICE
    )


    # Evaluation mode
    model.eval()


    return model, checkpoint


# ==========================================
# PREPROCESS IMAGE
# ==========================================

def preprocess_image(image_path):

    image_path = Path(
        image_path
    )


    if not image_path.exists():

        raise FileNotFoundError(

            f"Image not found:\n{image_path}"

        )


    # Open image
    image = Image.open(
        image_path
    ).convert(
        "RGB"
    )


    # Apply transform
    image_tensor = PREDICT_TRANSFORM(
        image
    )


    # Add batch dimension
    image_tensor = image_tensor.unsqueeze(
        0
    )


    return image_tensor


# ==========================================
# MAKE PREDICTION
# ==========================================

def predict(image_path):

    # Load model
    model, checkpoint = load_model()


    # Preprocess image
    image_tensor = preprocess_image(
        image_path
    )


    # Move to device
    image_tensor = image_tensor.to(
        DEVICE
    )


    # Disable gradients
    with torch.no_grad():

        outputs = model(
            image_tensor
        )


        probabilities = torch.softmax(

            outputs,

            dim=1

        )


    # Get predicted class
    predicted_index = torch.argmax(

        probabilities,

        dim=1

    ).item()


    # Convert probabilities
    probabilities = probabilities.squeeze().cpu()


    class_0_probability = float(
        probabilities[0].item()
    )


    class_1_probability = float(
        probabilities[1].item()
    )


    confidence = float(
        probabilities[
            predicted_index
        ].item()
    )


    # Create result
    result = {

        "predicted_class_index":
            predicted_index,

        "predicted_class":
            CLASS_NAMES[
                predicted_index
            ],

        "confidence":
            confidence,

        "class_0_probability":
            class_0_probability,

        "class_1_probability":
            class_1_probability,

        "model_epoch":
            checkpoint.get(
                "epoch"
            )

    }


    return result


# ==========================================
# COMMAND LINE
# ==========================================

def main():

    if len(sys.argv) < 2:

        print(
            "\nUsage:"
        )

        print(
            "python -m src.predict "
            "path/to/image.jpg"
        )

        return


    image_path = sys.argv[1]


    print("=" * 60)

    print(
        "FACIAL EXPRESSION PREDICTION"
    )

    print("=" * 60)


    result = predict(
        image_path
    )


    print(
        f"\nPredicted Class: "
        f"{result['predicted_class']}"
    )


    print(
        f"Confidence: "
        f"{result['confidence'] * 100:.2f}%"
    )


    print(
        f"\nClass 0 Probability: "
        f"{result['class_0_probability'] * 100:.2f}%"
    )


    print(
        f"Class 1 Probability: "
        f"{result['class_1_probability'] * 100:.2f}%"
    )


    print(
        f"\nModel Best Epoch: "
        f"{result['model_epoch']}"
    )


    print("\n" + "=" * 60)


if __name__ == "__main__":

    main()