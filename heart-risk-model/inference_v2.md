# python -m src.train_v2
======================================================================
HEART RISK MODEL V2
======================================================================

Loading dataset:
C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model\data\raw\framingham.csv

Rows after cleaning: 4240
Positive target rate: 0.1519

Training samples: 3392
Test samples: 848

======================================================================
Evaluating: logistic_regression_v2
======================================================================
ROC-AUC : 0.7369
PR-AUC  : 0.3601
Recall  : 0.6874
F1      : 0.3951

======================================================================
Evaluating: random_forest_v2
======================================================================
ROC-AUC : 0.7224
PR-AUC  : 0.3523
Recall  : 0.3204
F1      : 0.3489

======================================================================
Evaluating: xgboost_v1
======================================================================
ROC-AUC : 0.7137
PR-AUC  : 0.3511
Recall  : 0.0971
F1      : 0.1634

======================================================================
CROSS-VALIDATION RESULTS
======================================================================
                 model  roc_auc_mean  roc_auc_std  pr_auc_mean  pr_auc_std  accuracy_mean  precision_mean  recall_mean  f1_mean
logistic_regression_v2        0.7369       0.0296       0.3601      0.0332         0.6793          0.2775       0.68740.3951
      random_forest_v2        0.7224       0.0285       0.3523      0.0430         0.8181          0.3868       0.32040.3489
            xgboost_v1        0.7137       0.0299       0.3511      0.0323         0.8517          0.6004       0.09710.1634

Selected model: logistic_regression_v2

Training selected model...

======================================================================
HELD-OUT TEST RESULTS
======================================================================
ROC-AUC    : 0.6929
PR-AUC     : 0.2844
Accuracy   : 0.6722
Precision  : 0.2541
Recall     : 0.5969
F1         : 0.3565


======================================================================
MODEL SAVED
======================================================================
C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model\models\heart_risk_model_v2.joblib

Reports:
C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model\reports\v2_cv_results.csv
C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model\reports\v2_test_metrics.json
C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model\reports\v2_confusion_matrix.csv
PS C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model>


======================================================================
Final
======================================================================
Don't add:

steps
sleep
HRV
SpO₂
stress
activity

to this model yet.

We need to keep the clinical risk model conceptually clean.

Instead we'll eventually have:

MODEL A
Clinical cardiovascular risk
        ↓
Framingham-like variables
        ↓
10-year risk

and separately:

MODEL B
Daily cardiovascular wellness
        ↓
HR
HRV
BP
sleep
steps
activity
SpO₂
        ↓
Daily health score

Then your Pulse AI can combine them.

That's a much stronger architecture.

11. Our next phase

We're now at:

✅ Dataset acquired
✅ Data validation
✅ EDA
✅ Missing-value analysis
✅ Duplicate analysis
✅ Baseline Logistic Regression
✅ Random Forest
✅ XGBoost

Next:

                    NEXT
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
   Probability analysis      Hyperparameter
                             optimization
          │                       │
          ▼                       ▼
   Calibration curves       Logistic tuning
   Brier score              RF tuning
   Threshold analysis       XGBoost tuning
          │                       │
          └───────────┬───────────┘
                      ▼
                Model selection
                      │
                      ▼
                SHAP analysis
                      │
                      ▼
             Final validation
                      │
                      ▼
                  FastAPI



