-- ============================================
-- WEEK 1 WAREHOUSE BUILD QUERIES
-- 90-Day Data Bootcamp
-- ============================================

06/05/2026

-- "Three table star schema JOIN"

SELECT m.merchant_name, m.category, ROUND(SUM(t.amount),0) AS total_spend
FROM `your-project.transactions_warehouse.raw_transactions` t
INNER JOIN `your-project.transactions_warehouse.dim_merchant` m
ON t.merchant = m.merchant_name
AND t.category = m.category
INNER JOIN `your-project.transactions_warehouse.dim_date` d
ON t.txn_date = d.full_date
WHERE d.quarter = 'Q3'
GROUP BY m.merchant_name, m.category
ORDER BY total_spend DESC
LIMIT 3;

06/06/2026

-- ============================================
-- 1. Account summary — five aggregates
-- Morning drill — real data from BigQuery
-- ============================================
SELECT
    account_id,
    SUM(amount) AS total_spend,
    AVG(amount) AS average_transaction_amount,
    MAX(amount) AS largest_single_transaction,
    COUNT(txn_id) AS number_of_transactions,
    MAX(txn_date) AS most_recent_transaction_date
FROM `your-project-id.transactions_warehouse.raw_transactions`
GROUP BY account_id
ORDER BY total_spend DESC;


-- ============================================
-- 2. Create fct_transactions view
-- Replaces raw text columns with foreign keys
-- Connects all four tables into one clean view
-- ============================================
CREATE OR REPLACE VIEW `your-project-id.transactions_warehouse.fct_transactions` AS
SELECT
    t.txn_id,
    a.account_id,
    m.merchant_id,
    d.date_id,
    t.amount
FROM `your-project-id.transactions_warehouse.raw_transactions` t
JOIN `your-project-id.transactions_warehouse.dim_account` a
    ON t.account_id = a.account_id
JOIN `your-project-id.transactions_warehouse.dim_merchant` m
    ON t.merchant = m.merchant_name
    AND t.category = m.category
JOIN `your-project-id.transactions_warehouse.dim_date` d
    ON t.txn_date = d.full_date;


-- ============================================
-- 3. Validation queries
-- Run after every table build to confirm
-- data integrity before anyone queries it
-- ============================================

-- 3a. Row count — must match raw_transactions
SELECT COUNT(*) AS fct_count
FROM `your-project-id.transactions_warehouse.fct_transactions`;

-- 3b. Null check — no orphaned foreign keys
SELECT
    COUNTIF(account_id IS NULL) AS null_accounts,
    COUNTIF(merchant_id IS NULL) AS null_merchants,
    COUNTIF(date_id IS NULL) AS null_dates
FROM `your-project-id.transactions_warehouse.fct_transactions`;

-- 3c. Spot check — verify one row looks correct end to end
SELECT
    f.txn_id,
    f.amount,
    a.account_name,
    a.account_type,
    m.merchant_name,
    m.category,
    d.full_date,
    d.month_name,
    d.quarter,
    d.is_weekend
FROM `your-project-id.transactions_warehouse.fct_transactions` f
JOIN `your-project-id.transactions_warehouse.dim_account` a
    ON f.account_id = a.account_id
JOIN `your-project-id.transactions_warehouse.dim_merchant` m
    ON f.merchant_id = m.merchant_id
JOIN `your-project-id.transactions_warehouse.dim_date` d
    ON f.date_id = d.date_id
LIMIT 5;


-- ============================================
-- 4. Management report — spend by account type and quarter
-- First end-to-end query using only fct + dimensions
-- No raw tables — this is the warehouse working properly
-- ============================================
SELECT
    a.account_type,
    d.quarter,
    ROUND(SUM(f.amount), 0) AS total_spend
FROM `your-project-id.transactions_warehouse.fct_transactions` f
JOIN `your-project-id.transactions_warehouse.dim_account` a
    ON f.account_id = a.account_id
JOIN `your-project-id.transactions_warehouse.dim_date` d
    ON f.date_id = d.date_id
GROUP BY a.account_type, d.quarter
ORDER BY d.quarter, total_spend DESC;

06/07/2026

-- "From the complete star schema — no raw tables — return each merchant's total transactions, total spend, average spend per transaction, and their rank within their category by total spend. Show only merchants ranked 1 or 2 in their category."

WITH merchant_summary AS (
    SELECT
        m.merchant_id,
        m.merchant_name,
        m.category,
        COUNT(t.txn_id)          AS no_of_transactions,
        ROUND(SUM(t.amount), 0)  AS total_spend,
        ROUND(AVG(t.amount), 0)  AS avg_spend
    FROM `your-project-id.transactions_warehouse.fct_transactions` t
    JOIN `your-project-id.transactions_warehouse.dim_merchant` m
        ON t.merchant_id = m.merchant_id
    GROUP BY m.merchant_id, m.merchant_name, m.category
),
ranked AS (
    SELECT
        merchant_id,
        merchant_name,
        category,
        no_of_transactions,
        total_spend,
        avg_spend,
        RANK() OVER (PARTITION BY category
                     ORDER BY total_spend DESC) AS rnk
    FROM merchant_summary
)
SELECT *
FROM ranked
WHERE rnk <= 2
ORDER BY category, rnk;

-- Query 1: "Show the month over month spend trend for the full year 2024 — total spend per month across all accounts, with the previous month's spend and percentage change. 
-- Order chronologically."

WITH monthly_totals AS (
    SELECT
        d.month_number,
        d.month_name,
        ROUND(SUM(t.amount), 0) AS total_spend
    FROM `your-project-id.transactions_warehouse.fct_transactions` t
    JOIN `your-project-id.transactions_warehouse.dim_date` d
        ON t.date_id = d.date_id
    GROUP BY d.month_number, d.month_name
),
with_lag AS (
    SELECT
        month_number,
        month_name,
        total_spend,
        LAG(total_spend) OVER (ORDER BY month_number) AS prev_month_spend
    FROM monthly_totals
)
SELECT
    month_name,
    total_spend,
    prev_month_spend,
    ROUND((total_spend - prev_month_spend) / prev_month_spend * 100, 1)
        AS pct_change
FROM with_lag
ORDER BY month_number;

06/08/2026

-- "For each account type, show the single biggest spending day of the year — the date, total spend on that day, and how many transactions happened."

