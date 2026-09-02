import torch
import torch.nn as nn
import torchvision.models as models


# ==========================================
# FACIAL STRESS CNN (MOBILENET_V2 TRANSFER LEARNING)
# ==========================================

class FacialStressModel(nn.Module):

    def __init__(self, num_classes=2):

        super().__init__()


        # ==================================
        # LOAD PRE-TRAINED BACKBONE
        # ==================================

        self.backbone = models.mobilenet_v2(
            weights=models.MobileNet_V2_Weights.DEFAULT
        )


        # ==================================
        # FREEZE FEATURES
        # ==================================

        # We freeze the feature extraction layers so they retain
        # their ImageNet knowledge and don't overfit to our tiny dataset.
        for param in self.backbone.features.parameters():
            param.requires_grad = False


        # ==================================
        # REPLACE CLASSIFIER
        # ==================================

        # The original classifier outputs 1000 classes.
        # We replace it with our own head that outputs 2 classes.
        in_features = self.backbone.classifier[1].in_features

        self.backbone.classifier = nn.Sequential(
            nn.Dropout(p=0.5),
            nn.Linear(in_features, num_classes)
        )


    # ======================================
    # FORWARD PASS
    # ======================================

    def forward(self, x):

        # MobileNetV2 backbone handles features, pooling, and classification
        return self.backbone(x)