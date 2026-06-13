06/08/2026

-- Drill 1: ROW_NUMBER — rank transactions per account by amount
SELECT
  account_id,
  txn_id,
  amount,
  ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY amount DESC) AS rnk
FROM `your-project.transactions_warehouse.fct_transactions`
ORDER BY account_id, rnk;


-- Drill 2: DENSE_RANK — top transaction per account
WITH ranked_data AS (
  SELECT
    account_id,
    txn_id,
    amount,
    DENSE_RANK() OVER (PARTITION BY account_id ORDER BY amount DESC) AS rnk
  FROM `your-project.transactions_warehouse.fct_transactions`
)
SELECT account_id, txn_id, amount, rnk
FROM ranked_data
WHERE rnk = 1;


-- Drill 3: LAG — difference from previous transaction per account by date
WITH lag_data AS (
  SELECT
    t.account_id,
    d.full_date,
    t.amount,
    COALESCE(LAG(t.amount) OVER (PARTITION BY t.account_id ORDER BY d.full_date), 0) AS prev_txn_amount
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
)
SELECT
  account_id,
  full_date,
  ROUND(amount, 0) AS amount,
  ROUND(amount - prev_txn_amount, 0) AS diff
FROM lag_data
ORDER BY account_id, full_date;

06/10/2026

-- Drill 4: DATE_TRUNC — total spend per month
SELECT
  DATE_TRUNC(d.full_date, MONTH) AS month,
  ROUND(SUM(t.amount), 0) AS total_spend
FROM `your-project.transactions_warehouse.fct_transactions` t
JOIN `your-project.transactions_warehouse.dim_date` d
  ON t.date_id = d.date_id
GROUP BY DATE_TRUNC(d.full_date, MONTH)
ORDER BY month;


-- Drill 5: FORMAT_DATE + EXTRACT — total spend by day of week
SELECT
  EXTRACT(DAYOFWEEK FROM d.full_date) AS day_of_week,
  FORMAT_DATE('%A', d.full_date) AS day_name,
  ROUND(SUM(t.amount), 0) AS total_spend
FROM `your-project.transactions_warehouse.fct_transactions` t
JOIN `your-project.transactions_warehouse.dim_date` d
  ON t.date_id = d.date_id
GROUP BY
  EXTRACT(DAYOFWEEK FROM d.full_date),
  FORMAT_DATE('%A', d.full_date)
ORDER BY day_of_week;

-- Option A — Top merchants by spend
Which merchants received the most money? Rank them using DENSE_RANK, show total spend and transaction count per merchant.

SELECT
  m.merchant_name,
  ROUND(SUM(t.amount), 0) AS total_spend,
  COUNT(t.txn_id) AS txn_count,
  DENSE_RANK() OVER (ORDER BY SUM(t.amount) DESC) AS dense_rnk
FROM `your-project.transactions_warehouse.fct_transactions` t
JOIN `your-project.transactions_warehouse.dim_merchant` m
  ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_name
ORDER BY dense_rnk;

-- Option B — Monthly spending trend
-- How does total spend change month over month? Use DATE_TRUNC to bucket by month, then LAG to calculate the month-over-month change and percentage difference. 

-- Drill 6: MoM spending trend with LAG
WITH monthly_spend AS (
  SELECT
    DATE_TRUNC(d.full_date, MONTH) AS month,
    ROUND(SUM(t.amount), 0) AS total_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
  GROUP BY DATE_TRUNC(d.full_date, MONTH)
),
with_lag AS (
  SELECT
    month,
    total_spend,
    COALESCE(LAG(total_spend) OVER (ORDER BY month), 0) AS prev_month_spend
  FROM monthly_spend
)
SELECT
  month,
  total_spend,
  prev_month_spend,
  (total_spend - prev_month_spend) AS mom_change,
  ROUND(SAFE_DIVIDE(total_spend - prev_month_spend, prev_month_spend) * 100, 2) AS pct_change
FROM with_lag
ORDER BY month;

-- Option C — High-value accounts
-- Which accounts are in the top 20% by total lifetime spend? Use a window function to calculate each account's percentile.

-- Drill 7: NTILE — top 20% of accounts by lifetime spend
WITH grouped_data AS (
  SELECT
    account_id,
    ROUND(SUM(amount), 0) AS total_spend
  FROM `your-project.transactions_warehouse.fct_transactions`
  GROUP BY account_id
),
ntile_data AS (
  SELECT
    account_id,
    total_spend,
    NTILE(100) OVER (ORDER BY total_spend DESC) AS percentile
  FROM grouped_data
)
SELECT
  account_id,
  total_spend,
  percentile
FROM ntile_data
WHERE percentile <= 20
ORDER BY total_spend DESC;

-- Drill 8: Subquery version of merchant ranking (compare to CTE in Drill 6)
SELECT merchant_name, total_spend, total_txns, dense_rnk
FROM (
  SELECT
    m.merchant_name,
    ROUND(SUM(t.amount), 0) AS total_spend,
    COUNT(t.txn_id) AS total_txns,
    DENSE_RANK() OVER (ORDER BY SUM(t.amount) DESC) AS dense_rnk
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
  GROUP BY m.merchant_name
  ORDER BY dense_rnk
) AS dense_data;

06/12/2026

-- Drill 9 (no-AI): Total spend and avg transaction by category
SELECT
  m.category,
  ROUND(SUM(t.amount), 0) AS total_spend,
  ROUND(AVG(t.amount), 0) AS avg_txn_amount
FROM `your-project.transactions_warehouse.fct_transactions` t
JOIN `your-project.transactions_warehouse.dim_merchant` m
  ON t.merchant_id = m.merchant_id
GROUP BY m.category
ORDER BY total_spend DESC;


-- Drill 10 (no-AI): Accounts with >50 transactions, total spend
SELECT
  a.account_id,
  COUNT(t.txn_id) AS total_count,
  ROUND(SUM(t.amount), 0) AS total_spend
FROM `your-project.transactions_warehouse.fct_transactions` t
JOIN `your-project.transactions_warehouse.dim_account` a
  ON t.account_id = a.account_id
GROUP BY a.account_id
HAVING COUNT(t.txn_id) > 50
ORDER BY total_spend DESC;

-- Drill 11: Top 3 accounts by spend per merchant category (DENSE_RANK + PARTITION BY)
WITH group_data AS (
  SELECT
    t.account_id,
    m.category,
    ROUND(SUM(t.amount), 0) AS total_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
  GROUP BY t.account_id, m.category
),
rnk_data AS (
  SELECT
    account_id,
    category,
    total_spend,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY total_spend DESC) AS rnk
  FROM group_data
)
SELECT account_id, category, total_spend, rnk
FROM rnk_data
WHERE rnk <= 3
ORDER BY category, rnk;

-- Drill 12: Top-spending month per account (DENSE_RANK + PARTITION BY account_id)
WITH group_data AS (
  SELECT
    t.account_id,
    DATE_TRUNC(d.full_date, MONTH) AS month,
    ROUND(SUM(t.amount), 0) AS total_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
  GROUP BY t.account_id, DATE_TRUNC(d.full_date, MONTH)
),
rnk_data AS (
  SELECT
    account_id,
    month,
    total_spend,
    DENSE_RANK() OVER (PARTITION BY account_id ORDER BY total_spend DESC) AS rnk
  FROM group_data
)
SELECT account_id, month, total_spend, rnk
FROM rnk_data
WHERE rnk = 1
ORDER BY account_id;

