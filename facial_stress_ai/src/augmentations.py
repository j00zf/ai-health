from torchvision import transforms


TRAIN_TRANSFORM = transforms.Compose([

    transforms.ToTensor(),

    transforms.RandomHorizontalFlip(
        p=0.5
    ),

    transforms.RandomRotation(
        degrees=10
    ),

    transforms.RandomAffine(
        degrees=0,
        translate=(0.05, 0.05),
        scale=(0.95, 1.05)
    ),

    transforms.Normalize(
        mean=[0.5],
        std=[0.5]
    )

])


EVAL_TRANSFORM = transforms.Compose([

    transforms.ToTensor(),

    transforms.Normalize(
        mean=[0.5],
        std=[0.5]
    )

])