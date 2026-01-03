-- =========================================================
-- CUSTOMER CHURN ANALYSIS & RISK SCORING
-- Engine: DuckDB
-- Project: Customer Churn Analysis & Risk Scoring
--
-- IMPORTANT:
-- All churn and recency calculations are evaluated
-- relative to the dataset's observation window,
-- NOT the wall-clock current date.
-- =========================================================


-- ---------------------------------------------------------
-- 1. LOAD BASE TABLES
-- ---------------------------------------------------------

CREATE OR REPLACE TABLE users AS
SELECT * FROM read_csv_auto('C:\Projects\churnRisk\data\users.csv');

CREATE OR REPLACE TABLE orders AS
SELECT * FROM read_csv_auto('C:\Projects\churnRisk\data\orders.csv');

CREATE OR REPLACE TABLE reviews AS
SELECT * FROM read_csv_auto('C:\Projects\churnRisk\data\reviews.csv');

CREATE OR REPLACE TABLE events AS
SELECT * FROM read_csv_auto('C:\Projects\churnRisk\data\events.csv');
-- ---------------------------------------------------------
-- 2. DATASET REFERENCE ("AS-OF") DATE
-- ---------------------------------------------------------
-- This defines the end of the observation window.
-- All churn logic MUST anchor to this date.

CREATE OR REPLACE TABLE dataset_reference_date AS
SELECT
    GREATEST(
        (SELECT MAX(event_timestamp) FROM events),
        (SELECT MAX(order_date) FROM orders),
        (SELECT MAX(review_date) FROM reviews)
    ) AS as_of_date;


-- ---------------------------------------------------------
-- 3. USER LAST ACTIVITY SNAPSHOT
-- ---------------------------------------------------------
-- Activity includes:
-- - Any event (view, cart, wishlist, purchase)
-- - Any completed order

CREATE OR REPLACE TABLE user_last_activity AS
SELECT
    u.user_id,

    MAX(e.event_timestamp) AS last_event_date,

    MAX(
        CASE
            WHEN o.order_status = 'Completed'
            THEN o.order_date
        END
    ) AS last_order_date

FROM users u
LEFT JOIN events e
    ON u.user_id = e.user_id
LEFT JOIN orders o
    ON u.user_id = o.user_id
GROUP BY u.user_id;


-- ---------------------------------------------------------
-- 4. CONSOLIDATED ACTIVITY DATE
-- ---------------------------------------------------------
-- The most recent signal determines "activity"

CREATE OR REPLACE TABLE user_activity AS
SELECT
    user_id,
    last_event_date,
    last_order_date,

    GREATEST(
        COALESCE(last_event_date, DATE '1900-01-01'),
        COALESCE(last_order_date, DATE '1900-01-01')
    ) AS last_activity_date
FROM user_last_activity;


-- ---------------------------------------------------------
-- 5. CHURN LABEL DEFINITION
-- ---------------------------------------------------------
-- Churn Rule (v1):
-- No activity in the last 60 days relative to as_of_date
--
-- NOTE:
-- Users with no events or purchases are treated as churned
-- due to complete inactivity.

CREATE OR REPLACE TABLE churn_labels AS
SELECT
    ua.user_id,
    ua.last_activity_date,

    DATE_DIFF(
        'day',
        ua.last_activity_date,
        (SELECT as_of_date FROM dataset_reference_date)
    ) AS days_since_last_activity,

    CASE
        WHEN DATE_DIFF(
            'day',
            ua.last_activity_date,
            (SELECT as_of_date FROM dataset_reference_date)
        ) >= 60
        THEN 1
        ELSE 0
    END AS is_churned

FROM user_activity ua;


-- ---------------------------------------------------------
-- 6. FEATURE ENGINEERING (USER LEVEL)
-- ---------------------------------------------------------
-- Recency / Frequency / Monetary
-- Engagement velocity
-- Satisfaction signals

CREATE OR REPLACE TABLE churn_features AS
SELECT
    u.user_id,

    -- ----------------- RECENCY -----------------
    DATE_DIFF(
        'day',
        MAX(e.event_timestamp),
        (SELECT as_of_date FROM dataset_reference_date)
    ) AS recency_days,

    -- ---------------- FREQUENCY ----------------
    COUNT(DISTINCT e.event_id) AS total_events,
    COUNT(DISTINCT o.order_id) AS total_orders,

    -- ---------------- MONETARY -----------------
    COALESCE(SUM(o.total_amount), 0) AS total_spend,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,

    -- ----------- ENGAGEMENT VELOCITY ------------
    COUNT(
        CASE
            WHEN e.event_timestamp >=
                 (SELECT as_of_date FROM dataset_reference_date)
                 - INTERVAL 30 DAY
            THEN 1
        END
    ) AS events_last_30d,

    COUNT(
        CASE
            WHEN e.event_timestamp >=
                 (SELECT as_of_date FROM dataset_reference_date)
                 - INTERVAL 60 DAY
            THEN 1
        END
    ) AS events_last_60d,

    -- --------------- SATISFACTION --------------
    AVG(r.rating) AS avg_review_rating,
    COUNT(DISTINCT r.review_id) AS total_reviews

FROM users u
LEFT JOIN events e
    ON u.user_id = e.user_id
LEFT JOIN orders o
    ON u.user_id = o.user_id
   AND o.order_status = 'Completed'
LEFT JOIN reviews r
    ON u.user_id = r.user_id
GROUP BY u.user_id;


-- ---------------------------------------------------------
-- 7. FINAL MODELING TABLE
-- ---------------------------------------------------------
-- One table for EDA, ML, SHAP, dashboards

CREATE OR REPLACE TABLE churn_model_table AS
SELECT
    f.*,
    c.is_churned,
    c.days_since_last_activity
FROM churn_features f
LEFT JOIN churn_labels c
    ON f.user_id = c.user_id;


-- ---------------------------------------------------------
-- 8. SANITY CHECKS
-- ---------------------------------------------------------

-- Dataset reference date
SELECT * FROM dataset_reference_date;

-- Churn distribution
SELECT
    is_churned,
    COUNT(*) AS users
FROM churn_model_table
GROUP BY is_churned;

-- Overall churn rate
SELECT
    AVG(is_churned) AS churn_rate
FROM churn_model_table;

-- Distribution of days since last activity
SELECT
    CASE
        WHEN days_since_last_activity < 30 THEN '<30 days'
        WHEN days_since_last_activity < 60 THEN '30–59 days'
        WHEN days_since_last_activity < 90 THEN '60–89 days'
        ELSE '90+ days'
    END AS bucket,
    COUNT(*) AS users
FROM churn_model_table
GROUP BY bucket
ORDER BY bucket;