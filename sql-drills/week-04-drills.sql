06/22/2026

-- Session 16 Drill 1 — Correlated subquery: most recent transaction per account
-- Scalar correlated subquery in SELECT with ORDER BY + LIMIT 1 inside
-- Returns one value per outer row — must select single column only

SELECT
  a.account_name,
  (SELECT t.amount
   FROM `your-project.transactions_warehouse.fct_transactions` t
   LEFT JOIN `your-project.transactions_warehouse.dim_date` d
     ON t.date_id = d.date_id
   WHERE t.account_id = a.account_id
   ORDER BY d.full_date DESC
   LIMIT 1) AS recent_txn
FROM `your-project.transactions_warehouse.dim_account` a
ORDER BY recent_txn DESC;


-- Session 16 Drill 2 — Most recent transaction vs account average
-- ROW_NUMBER for latest transaction, separate CTE for account average
-- CASE WHEN compares the two values per account

WITH ranked AS (
  SELECT
    t.account_id,
    t.amount,
    ROW_NUMBER() OVER (PARTITION BY t.account_id ORDER BY d.full_date DESC) AS rn
  FROM `your-project.transactions_warehouse.fct_transactions` t
  LEFT JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
),
avg_amt AS (
  SELECT
    account_id,
    AVG(amount) AS acct_avg
  FROM `your-project.transactions_warehouse.fct_transactions`
  GROUP BY account_id
)
SELECT
  a.account_name,
  r.amount AS recent_txn,
  CASE
    WHEN r.amount > am.acct_avg THEN 'Above Average'
    ELSE 'Below Average'
  END AS label
FROM ranked r
JOIN avg_amt am ON r.account_id = am.account_id AND r.rn = 1
JOIN `your-project.transactions_warehouse.dim_account` a
  ON r.account_id = a.account_id
ORDER BY a.account_name;

06/23/2026

-- Session 17 Drill 1 — Self join: transaction pairs where one is more than double the other
-- Self join uses two aliases of the same table
-- t1.txn_id < t2.txn_id prevents duplicate pairs and self-matching
-- NOTE: returns large result set on full table — filter to specific account for testing

SELECT
  t1.account_id,
  CASE WHEN t1.amount > t2.amount THEN t1.amount ELSE t2.amount END AS higher_amount,
  CASE WHEN t1.amount > t2.amount THEN t2.amount ELSE t1.amount END AS lower_amount
FROM `your-project.transactions_warehouse.fct_transactions` t1
JOIN `your-project.transactions_warehouse.fct_transactions` t2
  ON t1.account_id = t2.account_id
  AND (t1.amount > 2 * t2.amount OR t2.amount > 2 * t1.amount)
WHERE t1.txn_id < t2.txn_id
  AND t1.account_id = 1;  -- filter to single account for testing

06/24/2026

-- Session 18 Drill 1 — Multi-level aggregation: months where 2+ categories
-- exceeded 8M in spend. CTE + WHERE preferred over HAVING for two-level aggregation.

WITH monthly_totals AS (
  SELECT
    m.category,
    DATE_TRUNC(d.full_date, MONTH) AS month,
    ROUND(SUM(t.amount), 0) AS total_monthly_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
  JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
  GROUP BY m.category, DATE_TRUNC(d.full_date, MONTH)
),
category_count AS (
  SELECT
    month,
    COUNT(category) AS total_category_count
  FROM monthly_totals
  WHERE total_monthly_spend > 8000000
  GROUP BY month
)
SELECT
  FORMAT_DATE('%Y-%m', month) AS yyyy_mm,
  total_category_count
FROM category_count
WHERE total_category_count > 1
ORDER BY yyyy_mm;

-- Session 18 Drill 2 — Running total of monthly spend
-- SUM OVER without explicit frame defaults to UNBOUNDED PRECEDING to CURRENT ROW
-- DATE_TRUNC drives grouping/ordering, FORMAT_DATE only at display layer

WITH monthly_totals AS (
  SELECT
    DATE_TRUNC(d.full_date, MONTH) AS month,
    ROUND(SUM(t.amount), 0) AS total_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
  GROUP BY DATE_TRUNC(d.full_date, MONTH)
)
SELECT
  FORMAT_DATE('%Y-%m', month) AS year_month,
  total_spend,
  SUM(total_spend) OVER (ORDER BY month) AS running_total
FROM monthly_totals
ORDER BY year_month;

06/26/2026

-- Session 19 Drill 1 — Top 2 categories per account type by spend in 2024
-- Multi-table star schema JOIN + DENSE_RANK + PARTITION BY + two-CTE chain

WITH category_totals AS (
  SELECT
    a.account_type,
    m.category,
    EXTRACT(YEAR FROM d.full_date) AS txn_year,
    ROUND(SUM(t.amount), 0) AS total_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
  JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
  JOIN `your-project.transactions_warehouse.dim_account` a
    ON t.account_id = a.account_id
  GROUP BY a.account_type, m.category, EXTRACT(YEAR FROM d.full_date)
),
ranked_categories AS (
  SELECT
    account_type,
    category,
    total_spend,
    DENSE_RANK() OVER (PARTITION BY account_type ORDER BY total_spend DESC) AS rnk
  FROM category_totals
  WHERE txn_year = 2024
)
SELECT account_type, category, total_spend, rnk
FROM ranked_categories
WHERE rnk <= 2
ORDER BY account_type, rnk;

06/27/2026

-- Session 20 Warm-up — Q3 vs Q4 2024 spend comparison per account
-- Conditional aggregation: SUM(CASE WHEN condition THEN value ELSE 0 END)
-- Assumes dim_date has a quarter column

WITH q_results AS (
  SELECT
    a.account_name,
    ROUND(SUM(CASE WHEN d.quarter = 'Q3' THEN t.amount ELSE 0 END), 0) AS q3_spend,
    ROUND(SUM(CASE WHEN d.quarter = 'Q4' THEN t.amount ELSE 0 END), 0) AS q4_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
  JOIN `your-project.transactions_warehouse.dim_account` a
    ON t.account_id = a.account_id
  WHERE d.full_date BETWEEN '2024-01-01' AND '2024-12-31'
  GROUP BY a.account_name
)
SELECT
  account_name,
  q3_spend,
  q4_spend,
  CASE
    WHEN q3_spend = q4_spend THEN 'No Change'
    WHEN q3_spend > q4_spend THEN 'Decreased'
    ELSE 'Increased'
  END AS label
FROM q_results
ORDER BY q4_spend DESC;


-- Session 20 Mock Interview Q1 — Merchant loyalty: accounts with more than
-- 3 distinct merchants. COUNT DISTINCT + HAVING pattern.

SELECT
  a.account_name,
  a.account_type,
  COUNT(DISTINCT t.merchant_id) AS distinct_merchant_count
FROM `your-project.transactions_warehouse.fct_transactions` t
JOIN `your-project.transactions_warehouse.dim_account` a
  ON t.account_id = a.account_id
GROUP BY a.account_name, a.account_type
HAVING COUNT(DISTINCT t.merchant_id) > 3
ORDER BY distinct_merchant_count DESC;


-- Session 20 Mock Interview Q2 — Accounts where H2 spend exceeds H1 spend
-- Conditional aggregation for half-year totals + WHERE on CTE aliases
-- CTE needed so H1/H2 aliases are available in WHERE clause

WITH half_totals AS (
  SELECT
    a.account_name,
    ROUND(SUM(CASE WHEN d.full_date BETWEEN '2024-01-01' AND '2024-06-30'
              THEN t.amount ELSE 0 END), 0) AS first_half_spend,
    ROUND(SUM(CASE WHEN d.full_date BETWEEN '2024-07-01' AND '2024-12-31'
              THEN t.amount ELSE 0 END), 0) AS second_half_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_account` a
    ON t.account_id = a.account_id
  JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
  GROUP BY a.account_name
)
SELECT
  account_name,
  first_half_spend,
  second_half_spend,
  ROUND(second_half_spend - first_half_spend, 0) AS difference
FROM half_totals
WHERE second_half_spend > first_half_spend
ORDER BY difference DESC;


-- Session 20 Mock Interview Q3 — Top 5 accounts by lifetime spend,
-- monthly spend + 3-month moving average per account
-- PARTITION BY account_name in moving average restarts window per account
-- 3 CTE version: one job per CTE — aggregate, rank, monthly totals

WITH agg_data AS (
  SELECT
    account_id,
    ROUND(SUM(amount), 0) AS lifetime_spend
  FROM `your-project.transactions_warehouse.fct_transactions`
  GROUP BY account_id
),
rnk_data AS (
  SELECT
    account_id,
    DENSE_RANK() OVER (ORDER BY lifetime_spend DESC) AS rnk
  FROM agg_data
),
filter_data AS (
  SELECT
    a.account_name,
    DATE_TRUNC(d.full_date, MONTH) AS month,
    ROUND(SUM(t.amount), 0) AS total_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN rnk_data g ON g.account_id = t.account_id AND g.rnk <= 5
  JOIN `your-project.transactions_warehouse.dim_account` a
    ON t.account_id = a.account_id
  JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
  GROUP BY a.account_name, DATE_TRUNC(d.full_date, MONTH)
)
SELECT
  account_name,
  FORMAT_DATE('%Y-%m', month) AS year_month,
  total_spend,
  ROUND(AVG(total_spend) OVER (
    PARTITION BY account_name
    ORDER BY month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 0) AS moving_avg
FROM filter_data
ORDER BY account_name, year_month;


-- Session 20 Mock Interview Q3 — 2 CTE alternative version
-- Ranking embedded as subquery in first CTE — fewer steps, slightly
-- harder to debug but good to know exists

WITH top_accounts AS (
  SELECT account_id
  FROM (
    SELECT
      account_id,
      DENSE_RANK() OVER (ORDER BY SUM(amount) DESC) AS rnk
    FROM `your-project.transactions_warehouse.fct_transactions`
    GROUP BY account_id
  )
  WHERE rnk <= 5
),
monthly_spend AS (
  SELECT
    a.account_name,
    DATE_TRUNC(d.full_date, MONTH) AS month,
    ROUND(SUM(t.amount), 0) AS total_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN top_accounts ta ON t.account_id = ta.account_id
  JOIN `your-project.transactions_warehouse.dim_account` a
    ON t.account_id = a.account_id
  JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
  GROUP BY a.account_name, DATE_TRUNC(d.full_date, MONTH)
)
SELECT
  account_name,
  FORMAT_DATE('%Y-%m', month) AS year_month,
  total_spend,
  ROUND(AVG(total_spend) OVER (
    PARTITION BY account_name
    ORDER BY month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 0) AS moving_avg
FROM monthly_spend
ORDER BY account_name, year_month;

06/28/2026

-- Session 21 Sunday Review — Bottom 1 category per account type
-- Same pattern as top-N but ORDER BY ASC reverses the ranking direction
-- DENSE_RANK preserves ties at the bottom

WITH category_totals AS (
  SELECT
    a.account_type,
    m.category,
    ROUND(SUM(t.amount), 0) AS total_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  JOIN `your-project.transactions_warehouse.dim_account` a
    ON t.account_id = a.account_id
  JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
  GROUP BY a.account_type, m.category
),
rnk_data AS (
  SELECT
    account_type,
    category,
    total_spend,
    DENSE_RANK() OVER (PARTITION BY account_type ORDER BY total_spend ASC) AS rnk
  FROM category_totals
)
SELECT account_type, category, total_spend
FROM rnk_data
WHERE rnk = 1;