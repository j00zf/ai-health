import torch
import torch.nn as nn


# ==========================================
# FACIAL STRESS CNN
# ==========================================

class FacialStressModel(nn.Module):

    def __init__(self, num_classes=2):

        super().__init__()


        # ==================================
        # FEATURE EXTRACTION
        # ==================================

        self.features = nn.Sequential(

            # ------------------------------
            # BLOCK 1
            # ------------------------------

            nn.Conv2d(
                in_channels=1,
                out_channels=32,
                kernel_size=3,
                padding=1
            ),

            nn.BatchNorm2d(32),

            nn.ReLU(),

            nn.MaxPool2d(
                kernel_size=2
            ),


            # ------------------------------
            # BLOCK 2
            # ------------------------------

            nn.Conv2d(
                in_channels=32,
                out_channels=64,
                kernel_size=3,
                padding=1
            ),

            nn.BatchNorm2d(64),

            nn.ReLU(),

            nn.MaxPool2d(
                kernel_size=2
            ),


            # ------------------------------
            # BLOCK 3
            # ------------------------------

            nn.Conv2d(
                in_channels=64,
                out_channels=128,
                kernel_size=3,
                padding=1
            ),

            nn.BatchNorm2d(128),

            nn.ReLU(),

            nn.MaxPool2d(
                kernel_size=2
            )

        )


        # ==================================
        # GLOBAL POOLING
        # ==================================

        self.global_pool = nn.AdaptiveAvgPool2d(
            (1, 1)
        )


        # ==================================
        # CLASSIFIER
        # ==================================

        self.classifier = nn.Sequential(

            nn.Flatten(),

            nn.Dropout(
                0.4
            ),

            nn.Linear(
                128,
                64
            ),

            nn.ReLU(),

            nn.Dropout(
                0.3
            ),

            nn.Linear(
                64,
                num_classes
            )

        )


    # ======================================
    # FORWARD PASS
    # ======================================

    def forward(self, x):

        x = self.features(x)

        x = self.global_pool(x)

        x = self.classifier(x)

        return x