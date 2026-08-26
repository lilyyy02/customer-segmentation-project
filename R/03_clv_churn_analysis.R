# ==============================================================================
# MARK5822 - RQ3: Customer Lifetime Value & Churn -> Priority Matrix
# NOTE: Reconstructed pipeline; CLV assumptions (10% margin, discount rate)
# should be confirmed against the group's actual methodology write-up.
# ==============================================================================

analysis_df <- readRDS("analysis_df_with_regression_inputs.rds")

# ---- 1. CLV estimation (simple one-year margin-based approximation) --------
margin_rate <- 0.10
discount_rate <- 0.10  # confirm against actual assumption used

analysis_df$CLV <- with(analysis_df,
                         monetary_spend * margin_rate / (1 + discount_rate))

clv_by_segment <- aggregate(CLV ~ segment, data = analysis_df, FUN = mean)
print(clv_by_segment)
# Expected pattern: Segment 1 (High-Value) CLV ~$753; Segment 3 (Dormant) CLV ~$7.5

# ---- 2. Churn model (2019 outcome, 2018 predictors only - no leakage) ------
churn_model <- glm(churned_2019 ~ recency_days + frequency_txn + monetary_spend +
                      Sat_Program + Sat_FastFood + Sat_Grocery + Sat_Petrol,
                    data = analysis_df, family = binomial(link = "logit"))
summary(churn_model)

analysis_df$churn_prob <- predict(churn_model, type = "response")

# Overall churn rate (expected ~24%)
mean(analysis_df$churned_2019)

# ---- 3. Priority matrix: CLV x churn risk -----------------------------------
clv_median <- median(analysis_df$CLV)
risk_median <- median(analysis_df$churn_prob)

analysis_df$priority_quadrant <- with(analysis_df, dplyr::case_when(
  CLV >= clv_median & churn_prob >= risk_median ~ "Priority (High CLV, High Risk)",
  CLV >= clv_median & churn_prob <  risk_median ~ "Protect (High CLV, Low Risk)",
  CLV <  clv_median & churn_prob <  risk_median ~ "Grow (Low CLV, Low Risk)",
  TRUE                                          ~ "Low Priority (Low CLV, High Risk)"
))

table(analysis_df$priority_quadrant)
# Presentation flags only 24 customers as "Priority" (High CLV + High Risk) -
# the main actionable retention target given limited budget.

# ---- 4. Export summary for the presentation's priority-matrix visual -------
write.csv(analysis_df[, c("customer_id", "segment", "CLV", "churn_prob",
                           "priority_quadrant")],
          "figures/priority_matrix_data.csv", row.names = FALSE)

# Limitations to note (Slide 14):
# - CLV based on simplifying assumptions (10% margin, discount rate)
# - Churn model uses a single year of data
# - Near-perfect separation in some logistic fits may affect generalisability
