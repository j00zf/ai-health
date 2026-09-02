import torch
import torch.nn as nn


# ==========================================
# FACIAL STRESS CNN (VGG-STYLE)
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

            nn.Conv2d(in_channels=3, out_channels=32, kernel_size=3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),

            nn.Conv2d(in_channels=32, out_channels=32, kernel_size=3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),

            nn.MaxPool2d(kernel_size=2),
            nn.Dropout2d(0.2),


            # ------------------------------
            # BLOCK 2
            # ------------------------------

            nn.Conv2d(in_channels=32, out_channels=64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),

            nn.Conv2d(in_channels=64, out_channels=64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),

            nn.MaxPool2d(kernel_size=2),
            nn.Dropout2d(0.3),


            # ------------------------------
            # BLOCK 3
            # ------------------------------

            nn.Conv2d(in_channels=64, out_channels=128, kernel_size=3, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(inplace=True),

            nn.Conv2d(in_channels=128, out_channels=128, kernel_size=3, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(inplace=True),

            nn.MaxPool2d(kernel_size=2),
            nn.Dropout2d(0.4)

        )


        # ==================================
        # GLOBAL POOLING
        # ==================================

        self.global_pool = nn.AdaptiveAvgPool2d((1, 1))


        # ==================================
        # CLASSIFIER
        # ==================================

        self.classifier = nn.Sequential(

            nn.Flatten(),

            nn.Dropout(0.5),

            nn.Linear(128, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(inplace=True),

            nn.Dropout(0.4),

            nn.Linear(128, num_classes)

        )

        # Initialize weights for proper convergence
        self._initialize_weights()


    # ======================================
    # WEIGHT INITIALIZATION
    # ======================================

    def _initialize_weights(self):
        for m in self.modules():
            if isinstance(m, nn.Conv2d):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.BatchNorm2d) or isinstance(m, nn.BatchNorm1d):
                nn.init.constant_(m.weight, 1)
                nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.Linear):
                nn.init.normal_(m.weight, 0, 0.01)
                nn.init.constant_(m.bias, 0)


    # ======================================
    # FORWARD PASS
    # ======================================

    def forward(self, x):

        x = self.features(x)
        x = self.global_pool(x)
        x = self.classifier(x)

        return x