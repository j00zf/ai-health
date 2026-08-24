Final Advanced Model Result
Model: Pulse AI Advanced v1
Threshold: 0.34 (selected from validation set, evaluated once on untouched test set)
Test Set Size: 14,000 records

Performance Metrics
Metric	Value
Accuracy	70.47%
Precision	66.01%
Recall	84.35%
F1	74.06%
ROC-AUC	0.7986
Average Precision	0.7785
Confusion Matrix


                         Predicted
                     0            1
                 ┌──────────┬──────────┐
Actual 0         │   3965   │   3039   │
                 │    TN    │    FP    │
                 ├──────────┼──────────┤
Actual 1         │   1095   │   5901   │
                 │    FN    │    TP    │
                 └──────────┴──────────┘
Breakdown:

True Negatives (TN): 3,965
False Positives (FP): 3,039
False Negatives (FN): 1,095
True Positives (TP): 5,901
Key Finding
Recall = 84.35%

The 0.34 operating threshold catches substantially more of the positive cases than the default 0.50 threshold, demonstrating improved sensitivity in identifying positive instances while maintaining reasonable overall performance across other metrics.


================================================================================
================================================================================
Pulse AI Advanced v1 achieved an ROC-AUC of 0.7986, accuracy of 70.47%, precision of 66.01%, recall of 84.35%, and F1-score of 74.06% on the held-out test set.
================================================================================
================================================================================