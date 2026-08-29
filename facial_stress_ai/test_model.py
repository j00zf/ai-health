import torch

from src.model import FacialStressModel
from src.config import DEVICE


def main():

    # --------------------------------------
    # CREATE MODEL
    # --------------------------------------

    model = FacialStressModel(
        num_classes=2
    )

    model = model.to(
        DEVICE
    )


    # --------------------------------------
    # PRINT MODEL
    # --------------------------------------

    print("=" * 60)
    print("FACIAL STRESS CNN")
    print("=" * 60)

    print(model)


    # --------------------------------------
    # DUMMY INPUT
    # --------------------------------------

    dummy_input = torch.randn(

        4,
        1,
        48,
        48

    ).to(
        DEVICE
    )


    # --------------------------------------
    # FORWARD PASS
    # --------------------------------------

    output = model(
        dummy_input
    )


    # --------------------------------------
    # RESULTS
    # --------------------------------------

    print("\n" + "=" * 60)

    print("MODEL TEST RESULTS")

    print("=" * 60)


    print("\nDevice:")

    print(
        DEVICE
    )


    print("\nInput shape:")

    print(
        dummy_input.shape
    )


    print("\nOutput shape:")

    print(
        output.shape
    )


    print("\nModel output:")

    print(
        output
    )


    # --------------------------------------
    # PARAMETER COUNT
    # --------------------------------------

    total_parameters = sum(

        parameter.numel()

        for parameter

        in model.parameters()

    )


    trainable_parameters = sum(

        parameter.numel()

        for parameter

        in model.parameters()

        if parameter.requires_grad

    )


    print("\nTotal parameters:")

    print(
        f"{total_parameters:,}"
    )


    print("\nTrainable parameters:")

    print(
        f"{trainable_parameters:,}"
    )


    print("\n" + "=" * 60)

    print(
        "MODEL TEST SUCCESSFUL"
    )

    print("=" * 60)


if __name__ == "__main__":

    main()