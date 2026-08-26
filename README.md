# FGP Loyalty Program: Customer Segmentation, Profiling & CLV/Churn Analysis

UNSW **MARK5822 — Marketing Analytics Tools** group project (2026)

Team: Lily Lei (z5620411), Songyun Zhang (z5620255), Zhe Yang (z5459640),
Yingying Zhang (z5521377), Zicheng Zhao (z5706210)

> ⚠️ **Data note**: the FGP customer transaction/survey dataset was provided
> by the course and is not included in this repository. It is **not**
> uploaded here — see [Data](#data) below. This is also a group project;
> confirm with teammates before making the repo public.
>
> ⚠️ **Code note**: the original R scripts used to produce the analysis were
> not retained outside the final presentation deck. The scripts in `R/` are
> a **reconstruction** of the described pipeline (PAM clustering, regression,
> CLV/churn) based on the methodology and reported results in
> `presentation/MARK5822_Presentation_H18A_z5620255.pptx`. Column names are
> illustrative placeholders — swap in the real FGP schema before running.

## Project overview

**Managerial problem:** FGP customers differ substantially in value, engagement,
and churn risk; a uniform retention strategy is inefficient given limited
retention budget.

**Research questions:**
1. **RQ1** — What customer segments exist? (RFM-based PAM clustering)
2. **RQ2** — What drives segment membership, spending, and NPS advocacy?
   (OLS + logistic regression on satisfaction/demographic predictors)
3. **RQ3** — How do customer value and individual churn risk differ, and
   where should retention investment be targeted? (CLV estimation + churn
   probability → priority matrix)

## Method summary

| Step | Method | Notes |
|---|---|---|
| Segmentation | PAM clustering on 2018 RFM (Recency, Frequency, Monetary) | k=3 selected via `NbClust` (23-index majority vote), confirmed by Hubert/D-index |
| Profiling | OLS (spending) + logistic regression (high-value membership, NPS Promoter) | IVs: 4-dim satisfaction (Program/FastFood/Grocery/Petrol) + demographics |
| Value & risk | CLV estimation (10% margin assumption) + churn logistic model on 2019 outcome | RFM computed from 2018 only, churn observed in 2019 — avoids information leakage |

## Repo structure

```
mark5822-customer-segmentation/
├── R/
│   ├── 01_rfm_segmentation.R      # RFM construction + PAM clustering (RQ1)
│   ├── 02_segment_profiling.R     # OLS + logistic regression (RQ2)
│   └── 03_clv_churn_analysis.R    # CLV estimation + churn model + priority matrix (RQ3)
├── presentation/
│   └── MARK5822_Presentation_H18A_z5620255.pptx   # Final group presentation deck
├── figures/                        # (export cluster plots, priority matrix, etc. here)
├── .gitignore
└── README.md
```

## Data

Not included. The scripts expect a data frame with (at minimum) these columns
— rename to match your actual FGP extract:

- `customer_id`
- 2018 transaction-level fields to derive `recency_days`, `frequency_txn`, `monetary_spend`
- `Sat_Program`, `Sat_FastFood`, `Sat_Grocery`, `Sat_Petrol` (satisfaction scores)
- `Gender`, `OwnCar`, `OwnCreditCard`, `BirthYear`/`Age`, `Tenure`
- `NPS_Score` (or pre-classified Promoter/Passive/Detractor)
- `Active2018`, `Active2019` (used to derive `Churned`)

## Key results (from the presentation)

| Segment | Label | n | Share | Avg Recency | Avg Freq. | Avg Spend | 2019 Churn | Avg CLV |
|---|---|---|---|---|---|---|---|---|
| 1 | High-Value | 1,968 | 61.2% | 17.2 days | 36.3 | $1,181 | 7.9% | ~$753 |
| 2 | At-Risk | 789 | 24.5% | 120 days | 8.1 | $234 | 38.1% | — |
| 3 | Dormant | 457 | 14.2% | 268 days | 4.1 | $98 | 71.1% | ~$7.5 |

**RQ2 highlights:** Petrol satisfaction is the strongest spending driver
(β = 0.291, p<0.001); car owners spend 21% more and are 41% more likely to
be high-value (OR = 1.41); Program satisfaction is the dominant driver of
NPS advocacy (OR = 3.02) and female customers are 3.4× more likely to be
Promoters (OR = 3.39).

**RQ3 highlights:** Only 24 customers fall into the "High CLV + High Risk"
priority quadrant — the main actionable retention target.

Full detail, all regression tables, and the priority-matrix visual are in
the presentation deck.

## How to run

```r
install.packages(c("cluster", "NbClust", "factoextra", "car"))
source("R/01_rfm_segmentation.R")
source("R/02_segment_profiling.R")
source("R/03_clv_churn_analysis.R")
```
