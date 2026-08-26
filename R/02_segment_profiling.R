# ==============================================================================
# MARK5822 - RQ2: Segment Profiling via Regression Analysis
# NOTE: Reconstructed pipeline; replace placeholder data-loading step with the
# actual FGP survey + transaction extract, joined with segments from
# 01_rfm_segmentation.R.
# ==============================================================================

library(car)  # vif()

rfm <- readRDS("rfm_with_segments.rds")

# ---- 1. Join RFM/segments with satisfaction survey + demographics ----------
# survey_demo: customer_id, Sat_Program, Sat_FastFood, Sat_Grocery, Sat_Petrol,
#              Gender, OwnCar, OwnCreditCard, BirthYear, Tenure, NPS_Score

analysis_df <- rfm |>
  dplyr::left_join(survey_demo, by = "customer_id") |>
  dplyr::mutate(
    high_value = ifelse(segment == "1", 1, 0),   # segment 1 = High-Value
    nps_promoter = ifelse(NPS_Score >= 9, 1, 0),
    log_spend = log1p(monetary_spend)
  )

# ---- 2. Model 1 (OLS): drivers of spending ----------------------------------
m1 <- lm(log_spend ~ Sat_Program + Sat_FastFood + Sat_Grocery + Sat_Petrol +
           Gender + OwnCar + OwnCreditCard + Tenure,
         data = analysis_df)
summary(m1)
vif(m1)

# Expected pattern (Slide 9):
# - Petrol satisfaction strongest driver (b ~ 0.291***)
# - Program (0.169***) and Grocery (0.136***) also positive & significant
# - FastFood satisfaction small negative effect (-0.028*) -> possible channel substitution
# - Car owners spend ~21% more (0.193***); longer tenure -> lower spend (-0.080***)

# ---- 3. Model 2 (Logistic): drivers of high-value membership ---------------
m2 <- glm(high_value ~ Sat_Program + Sat_FastFood + Sat_Grocery + Sat_Petrol +
            Gender + OwnCar + OwnCreditCard + Tenure,
          data = analysis_df, family = binomial(link = "logit"))
summary(m2)
exp(coef(m2))  # odds ratios

# Expected pattern:
# - Program satisfaction strongest predictor of high-value membership (OR ~ 1.34***)
# - Car owners 41% more likely to be high-value (OR ~ 1.41***)
# - Credit card holders less likely to be high-value (OR ~ 0.77**)

# ---- 4. Model 3 (Logistic): drivers of NPS advocacy -------------------------
m3 <- glm(nps_promoter ~ Sat_Program + Sat_FastFood + Sat_Grocery + Sat_Petrol +
            Gender + OwnCar + OwnCreditCard + Tenure,
          data = analysis_df, family = binomial(link = "logit"))
summary(m3)
exp(coef(m3))

# Expected pattern:
# - Program satisfaction dominates NPS advocacy (OR ~ 3.02***)
# - Female customers ~3.4x more likely to be Promoters (OR ~ 3.39***)

# ---- 5. ANOVA: satisfaction differs significantly across segments ----------
anova_program <- aov(Sat_Program ~ segment, data = analysis_df)
summary(anova_program)  # expect p < 0.001, repeat for FastFood / Grocery / Petrol

saveRDS(analysis_df, "analysis_df_with_regression_inputs.rds")
