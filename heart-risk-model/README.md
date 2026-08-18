# Heart Risk Model

Starter ML project for the Pulse AI heart-risk prediction service.

## Goal

Version 1 predicts the `TenYearCHD` outcome from the commonly distributed Framingham Heart Study teaching/ML dataset.

**Important:** this is a research/engineering model, not a clinically validated diagnostic system. The public Framingham data commonly used in ML tutorials is a derived dataset; official Framingham data access is handled through the Framingham Heart Study/NHLBI repositories.

## Project structure

```text
heart-risk-model/
├── data/
│   ├── raw/                  # put the CSV here
│   └── processed/
├── models/
├── reports/
├── src/
│   ├── config.py
│   ├── data.py
│   ├── evaluate.py
│   ├── predict.py
│   └── train.py
├── requirements.txt
└── README.md
```

## 1. Create environment

### Windows PowerShell

```powershell
cd heart-risk-model
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### macOS/Linux

```bash
cd heart-risk-model
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 2. Add the dataset

Put the CSV you are using in:

```text
data/raw/framingham.csv
```

The commonly used Framingham ML dataset has a target named:

```text
TenYearCHD
```

Typical columns include:

```text
male
age
education
currentSmoker
cigsPerDay
BPMeds
prevalentStroke
prevalentHyp
diabetes
totChol
sysBP
diaBP
BMI
heartRate
glucose
TenYearCHD
```

Do not download restricted FHS research data automatically with this project. Use a dataset you are legally permitted to use and retain its source/license information.

## 3. Train

```bash
python -m src.train
```

The training script:

- validates required columns
- separates train/test before fitting preprocessing
- imputes missing values inside a pipeline
- encodes categorical variables
- compares Logistic Regression and Random Forest
- uses stratified 5-fold cross-validation on the training set
- evaluates the selected model once on the held-out test set
- saves the complete preprocessing + model pipeline

Outputs:

```text
models/heart_risk_model.joblib
models/model_metadata.json
reports/test_metrics.json
reports/confusion_matrix.csv
reports/feature_importance.csv
```

## 4. Test a prediction

After training:

```bash
python -m src.predict
```

This runs a small example through the saved model.

## 5. Next phase

After this baseline is working, we will add:

1. XGBoost/LightGBM comparison
2. probability calibration
3. SHAP explanations
4. FastAPI `/predict` endpoint
5. Google Health/Health Connect feature mapping
6. daily cardiovascular wellness model
7. Groq explanation layer

## Medical-use warning

Do not present the output as a diagnosis or as a clinically validated "heart score." The first version is a machine-learning research model. Before any real clinical decision use, the model would require appropriate external validation, calibration, population-specific evaluation, governance, and clinical/regulatory review.
