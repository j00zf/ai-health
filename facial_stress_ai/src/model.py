import torch.nn as nn

from torchvision.models import (
    efficientnet_b0,
    EfficientNet_B0_Weights
)


class FacialStressModel(nn.Module):

    def __init__(self, num_classes=2):

        super().__init__()


        # ----------------------------------
        # PRETRAINED BACKBONE
        # ----------------------------------

        self.backbone = efficientnet_b0(

            weights=EfficientNet_B0_Weights.DEFAULT

        )


        # ----------------------------------
        # GET FEATURE SIZE
        # ----------------------------------

        input_features = (

            self.backbone
            .classifier[1]
            .in_features

        )


        # ----------------------------------
        # REMOVE ORIGINAL CLASSIFIER
        # ----------------------------------

        self.backbone.classifier = nn.Identity()


        # ----------------------------------
        # CUSTOM STRESS CLASSIFIER
        # ----------------------------------

        self.classifier = nn.Sequential(

            nn.Linear(
                input_features,
                512
            ),

            nn.BatchNorm1d(512),

            nn.ReLU(),

            nn.Dropout(0.4),


            nn.Linear(
                512,
                128
            ),

            nn.BatchNorm1d(128),

            nn.ReLU(),

            nn.Dropout(0.3),


            nn.Linear(
                128,
                num_classes
            )

        )


    def forward(self, x):

        features = self.backbone(x)

        output = self.classifier(features)

        return output