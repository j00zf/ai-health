# PS C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model> python -m src.calibration
======================================================================
HEART RISK MODEL - CALIBRATION & THRESHOLD ANALYSIS
======================================================================

Training records: 3392
Test records held out: 848

======================================================================
MODEL: logistic_regression_v2
======================================================================
Generating uncalibrated out-of-fold predictions...
Generating sigmoid-calibrated out-of-fold predictions...
Generating isotonic-calibrated out-of-fold predictions...

Probability metrics:
                 model  calibration  roc_auc  pr_auc  brier_score  log_loss
logistic_regression_v2 uncalibrated   0.7359  0.3472       0.2067    0.6017
logistic_regression_v2      sigmoid   0.7361  0.3483       0.1156    0.3783
logistic_regression_v2     isotonic   0.7338  0.3396       0.1160    0.4082

======================================================================
MODEL: random_forest_v2
======================================================================
Generating uncalibrated out-of-fold predictions...
Generating sigmoid-calibrated out-of-fold predictions...
Generating isotonic-calibrated out-of-fold predictions...

Probability metrics:
           model  calibration  roc_auc  pr_auc  brier_score  log_loss
random_forest_v2 uncalibrated   0.7207  0.3433       0.1425    0.4512
random_forest_v2      sigmoid   0.7223  0.3430       0.1169    0.3838
random_forest_v2     isotonic   0.7201  0.3386       0.1167    0.3848

======================================================================
MODEL: xgboost_v1
======================================================================
Generating uncalibrated out-of-fold predictions...
Generating sigmoid-calibrated out-of-fold predictions...
Generating isotonic-calibrated out-of-fold predictions...

Probability metrics:
     model  calibration  roc_auc  pr_auc  brier_score  log_loss
xgboost_v1 uncalibrated   0.7120  0.3391       0.1178    0.3883
xgboost_v1      sigmoid   0.7145  0.3396       0.1174    0.3880
xgboost_v1     isotonic   0.7139  0.3379       0.1170    0.3856

======================================================================
COMBINED PROBABILITY RESULTS
======================================================================
                 model  calibration  roc_auc  pr_auc  brier_score  log_loss
logistic_regression_v2 uncalibrated   0.7359  0.3472       0.2067    0.6017
logistic_regression_v2      sigmoid   0.7361  0.3483       0.1156    0.3783
logistic_regression_v2     isotonic   0.7338  0.3396       0.1160    0.4082
      random_forest_v2 uncalibrated   0.7207  0.3433       0.1425    0.4512
      random_forest_v2      sigmoid   0.7223  0.3430       0.1169    0.3838
      random_forest_v2     isotonic   0.7201  0.3386       0.1167    0.3848
            xgboost_v1 uncalibrated   0.7120  0.3391       0.1178    0.3883
            xgboost_v1      sigmoid   0.7145  0.3396       0.1174    0.3880
            xgboost_v1     isotonic   0.7139  0.3379       0.1170    0.3856

======================================================================
BEST CALIBRATION RESULTS
======================================================================

Best Brier score:
Model       : logistic_regression_v2
Calibration : sigmoid
Brier score : 0.115602

Best log loss:
Model       : logistic_regression_v2
Calibration : sigmoid
Log loss    : 0.378312

======================================================================
ANALYSIS COMPLETE
======================================================================

Reports saved to:
C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model\reports\calibration

Plots saved to:
C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model\reports\calibration\plots
PS C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model> Get-Content reports\calibration\all_probability_metrics.csv
model,calibration,roc_auc,pr_auc,brier_score,log_loss
logistic_regression_v2,uncalibrated,0.7359176056504382,0.347236121361938,0.20665797781124798,0.6017114619219467
logistic_regression_v2,sigmoid,0.7361079333583054,0.34830969871984707,0.11560182152638913,0.37831223636742056
logistic_regression_v2,isotonic,0.7338270380081734,0.33956268597685507,0.11597168547539771,0.408222135345109
random_forest_v2,uncalibrated,0.7206535934478674,0.3432879138991072,0.14249520220032513,0.4511814977699975
random_forest_v2,sigmoid,0.7223064748541328,0.3429500646817507,0.1168566854440877,0.383788815415141
random_forest_v2,isotonic,0.7201001582689628,0.3385588693948736,0.11672500659417644,0.3847927040651843
xgboost_v1,uncalibrated,0.7120338405364272,0.3391485533860917,0.11778893679723137,0.38831466004902415
xgboost_v1,sigmoid,0.7145178870924744,0.33955216609941224,0.11739851192035486,0.3879612698350488
xgboost_v1,isotonic,0.7138935852138318,0.337865758969849,0.11697131073535634,0.3856281652578596
PS C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model> 

# reports/calibration/plots/logistic_regression_v2_calibration_curves.png

# For the current feature set:

Logistic Regression + Sigmoid calibration is our best candidate.

Its out-of-fold results are:

Model	Calibration	ROC-AUC	PR-AUC	Brier ↓	Log Loss ↓
Logistic Regression V2	Sigmoid	0.7361	0.3483	0.1156	0.3783
Logistic Regression V2	Isotonic	0.7338	0.3396	0.1160	0.4082
Random Forest V2	Sigmoid	0.7223	0.3430	0.1169	0.3838
XGBoost V1	Isotonic	0.7139	0.3379	0.1170	0.3856

So there isn't a reason to move to XGBoost just because it's more complex.