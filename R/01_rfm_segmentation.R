# ==============================================================================
# MARK5822 - RQ1: RFM Construction & PAM Clustering
# NOTE: Reconstructed pipeline based on the methodology described in the
# group presentation. Replace `raw_transactions` / `raw_customers` below with
# the actual FGP data extract, and adjust column names accordingly.
# ==============================================================================

library(cluster)      # pam()
library(NbClust)      # k selection
library(factoextra)   # cluster visualisation

# ---- 1. Load data (placeholder - replace with actual FGP extract) ----------
# raw_transactions: one row per 2018 transaction, columns: customer_id, txn_date, amount
# raw_customers:    one row per customer, columns: customer_id, Active2018, Active2019, ...

# raw_transactions <- read.csv("data/fgp_transactions_2018.csv")
# raw_customers    <- read.csv("data/fgp_customers.csv")

# ---- 2. Build RFM (2018 only - avoids leakage into 2019 churn outcome) -----
reference_date <- as.Date("2019-01-01")

rfm <- raw_transactions |>
  dplyr::group_by(customer_id) |>
  dplyr::summarise(
    recency_days  = as.numeric(reference_date - max(as.Date(txn_date))),
    frequency_txn = dplyr::n(),
    monetary_spend = sum(amount),
    .groups = "drop"
  )

summary(rfm[, c("recency_days", "frequency_txn", "monetary_spend")])
# Expect strong right-skew (mean >> median) - motivates clustering over simple averages

# ---- 3. Standardise RFM variables -------------------------------------------
rfm_scaled <- scale(rfm[, c("recency_days", "frequency_txn", "monetary_spend")])

# ---- 4. Select k via NbClust (majority rule across 23 indices) --------------
set.seed(2026)
nb <- NbClust(rfm_scaled, distance = "euclidean", min.nc = 2, max.nc = 6,
              method = "kmeans", index = "all")
table(nb$Best.nc[1, ])
# Majority rule + Hubert/D-index structural break -> k = 3

# ---- 5. PAM clustering (robust to outliers vs. K-means) ---------------------
k <- 3
pam_fit <- pam(rfm_scaled, k = k)
rfm$segment <- factor(pam_fit$clustering)

fviz_cluster(pam_fit, data = rfm_scaled, geom = "point", ellipse.type = "norm") +
  ggplot2::labs(title = "PAM Clustering: FGP Customer Segments (2018 RFM)")

# ---- 6. Segment profile table -----------------------------------------------
segment_profile <- rfm |>
  dplyr::left_join(raw_customers[, c("customer_id", "Active2018", "Active2019")],
                    by = "customer_id") |>
  dplyr::mutate(churned_2019 = ifelse(Active2018 == "Y" & Active2019 == "N", 1, 0)) |>
  dplyr::group_by(segment) |>
  dplyr::summarise(
    n = dplyr::n(),
    share = n / nrow(rfm),
    avg_recency = mean(recency_days),
    avg_frequency = mean(frequency_txn),
    avg_spend = mean(monetary_spend),
    churn_rate_2019 = mean(churned_2019),
    .groups = "drop"
  )
print(segment_profile)

# Expected pattern (see presentation Table, Slide 5):
# Segment 1 "High-Value"  (~61%): low recency, high freq/spend, ~7.9% churn
# Segment 2 "At-Risk"     (~25%): moderate recency/freq, ~38.1% churn
# Segment 3 "Dormant"     (~14%): high recency, low freq/spend, ~71.1% churn

# Label segments by descending average spend
label_map <- segment_profile |>
  dplyr::arrange(dplyr::desc(avg_spend)) |>
  dplyr::mutate(label = c("High-Value", "At-Risk", "Dormant"))
print(label_map)

saveRDS(rfm, "rfm_with_segments.rds")
