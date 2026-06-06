-- ============================================
-- WEEK 1 WAREHOUSE BUILD QUERIES
-- 90-Day Data Bootcamp
-- ============================================

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