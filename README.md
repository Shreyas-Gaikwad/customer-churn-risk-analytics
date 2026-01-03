# Customer Churn Risk Analytics & Explainable Risk Scoring

<img width="1903" height="1931" alt="ChurnDashboard" src="https://github.com/user-attachments/assets/2532221d-7f6e-48cc-9438-dbba727f2314" />

An end-to-end **customer churn analysis and risk scoring project** built on an e-commerce dataset.
This project demonstrates how a **data analyst approaches churn through structured behavioral analysis**, followed by Python-based validation, explainable machine learning, and an executive-ready interactive dashboard.

The focus is on **understanding behavioral disengagement, defining churn rigorously, and translating inactivity signals into actionable retention insights**.

---

## Features

* SQL-first churn definition and feature engineering
* Explicit inactivity-based churn logic (temporal, not calendar-driven)
* User-level engagement and purchasing behavior analysis
* Cohort-based churn analysis (signup month)
* Behavioral decay analysis prior to churn
* Explainable churn modeling (logistic regression)
* SHAP-based interpretation of churn drivers
* Churn risk probability scoring per user
* Risk bucketing (Low / Medium / High)
* Executive-grade interactive Dash dashboard (light theme)

---

## System Architecture

```
Raw E-commerce Data (CSV)
   |
   v
SQL-Based Activity Aggregation & Churn Labeling
   |
   v
User-Level Feature Engineering (Recency, Frequency, Monetary)
   |
   v
Behavioral & Cohort Analysis (EDA)
   |
   v
Explainable Churn Modeling (Python)
   |
   v
Risk Scoring & Segmentation
   |
   v
Interactive Analytics Dashboard (Dash + Plotly)
```

---

## Analytical Approach

### Churn Definition

Churn is **explicitly defined**, rather than assumed.

**Churn Rule (v1):**

```
A user is considered churned if there is no recorded activity
(events or completed purchases) in the last 60 days
relative to the dataset's observation end date.
```

Key analyst decisions:

* Churn is evaluated against the **dataset observation window**, not the wall-clock date
* Any meaningful activity (events or purchases) resets inactivity
* Users with no recorded activity are treated as churned due to complete disengagement

This mirrors how churn is defined in real product analytics teams.

---

### Core Analytical Logic

SQL is used to construct transparent, reproducible churn logic and user-level features before any modeling or visualization.

This layer ensures:

* Clear business definitions
* Auditable assumptions
* Stable inputs for downstream analysis

Core analytical outputs include:

* User-level last activity snapshots
* Inactivity-based churn labels
* Recency, frequency, and monetary (RFM-style) features
* Engagement velocity metrics (30d / 60d activity)
* A final modeling table consumed by Python

---

### Exploratory Data Analysis (EDA)

EDA focuses on **behavioral decay**, not surface-level statistics:

* Distribution of inactivity duration
* Churn rate across signup cohorts
* Engagement drop-off prior to churn
* Relationship between inactivity and purchasing behavior
* Satisfaction signals (ratings) vs churn

The analysis shows that **churn is gradual**, with a clear early-risk window (30–59 days inactive).

---

### Explainable Churn Modeling

A **logistic regression model** is used intentionally for explainability.

Features include:

* Days since last activity
* Recent engagement volume
* Purchase frequency and spend
* Average order value
* Review-based satisfaction signal

The model is standardized to allow:

* Coefficient comparability
* SHAP-based global and local explanations

Rather than maximizing raw accuracy, the model is used to:

* Validate behavioral hypotheses
* Rank users by churn risk
* Provide interpretable drivers for decision-making

---

### Churn Risk Scoring

Each user receives:

* A churn probability score
* A business-friendly risk bucket:

```
0.00 – 0.30 → Low Risk
0.30 – 0.60 → Medium Risk
0.60 – 1.00 → High Risk
```

These buckets are designed for **retention prioritization**, not academic classification.

---

## Dashboard

The interactive Dash dashboard provides:

* Executive KPI summary (churn rate, active users, risk distribution)
* Churn risk score distribution
* Risk bucket segmentation
* Inactivity duration analysis
* Cohort-level churn trends
* High-risk user table for actionability

The dashboard is designed to resemble **internal churn monitoring tools used by product, growth, and retention teams**, with a strong emphasis on clarity and decision support.

---

## Data

### Dataset Description

The project uses an **e-commerce dataset** consisting of:

* Users
* Products
* Orders and order items
* Reviews
* Event-level behavioral logs

### Tables

* `users.csv` – User demographics and signup information
* `products.csv` – Product catalog with pricing and ratings
* `orders.csv` – Order-level transactions
* `order_items.csv` – Product-level purchase details
* `reviews.csv` – User reviews and ratings
* `events.csv` – User behavioral events (view, cart, wishlist, purchase)

---

## Project Structure

```
customer-churn-risk-analytics/
├── README.md
├── requirements.txt
├── sql/
│   └── churn_analysis.sql
└── notebooks/
    └── churnEDA.ipynb
```

The structure emphasizes **SQL-driven analysis first**, followed by Python-based modeling and dashboarding in a single, cohesive notebook.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/Shreyas-Gaikwad/customer-churn-risk-analytics.git
cd customer-churn-risk-analytics
```

Create a virtual environment and install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

---

## Usage

1. Review and run the SQL script in `sql/churn_analysis.sql` to understand churn logic
2. Open `notebooks/churnEDA.ipynb`
3. Run the notebook sequentially:

   * Data loading
   * EDA
   * Churn modeling & SHAP
   * Risk scoring
   * Dashboard launch

The Dash dashboard is launched **from within the notebook itself**.

Once running, open in your browser at:

```
http://127.0.0.1:8050
```

---

## Key Learnings

* Churn must be **defined explicitly**, not inferred
* Inactivity is the strongest churn signal in behavioral systems
* SQL remains the backbone of trustworthy analytics
* Explainability is critical for stakeholder trust
* Risk scoring is more useful than binary churn labels
* Dashboards are effective only when built around decisions

---

## Contributing

Contributions are welcome.

Please open issues or submit pull requests for:

* Alternative churn definitions (30 / 90 days)
* Additional behavioral features
* Retention strategy simulations
* Dashboard enhancements
* Documentation improvements

---

## Author

Built by **Shreyas Gaikwad**
Focus: Data Analytics, Product Analytics, and Applied Machine Learning
