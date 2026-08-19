# first model was:

Logistic Regression
+
Random Forest

# First Traing with Logistic Regression and Random Forest
PS C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model> python -m src.train
Loading: C:\Users\lenovo\Documents\MSc Ai\Mini-Project\heart-risk-model\data\raw\framingham.csv
Rows after basic cleaning: 4240
Positive target rate: 0.1519

Cross-validation results:
              model  roc_auc_mean  roc_auc_std  pr_auc_mean  accuracy_mean  precision_mean  recall_mean  f1_mean
logistic_regression      0.732258     0.032143     0.356711       0.674249        0.274599     0.691262 0.392788
      random_forest      0.717766     0.029516     0.342632       0.812801        0.367863     0.312621 0.336472

Selected model: logistic_regression

Held-out test metrics:
   roc_auc: 0.7000
    pr_auc: 0.2969
  accuracy: 0.6686
 precision: 0.2532
    recall: 0.6047
        f1: 0.3570

# Why XGBoost is the next model

dataset has only ~4,000 records.
This isn't a situation where I'd immediately use a neural network.
XGBoost is much more appropriate for this type of tabular data.
It can learn relationships such as:

Age + BP
Age + smoking
Age + diabetes
BP + hypertension
BMI + diabetes

rather than relying mainly on linear relationships.

For example, Logistic Regression essentially learns:

risk =
β0
+ β1(age)
+ β2(BP)
+ β3(glucose)
+ ...

