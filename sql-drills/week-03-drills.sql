06/15/2026

-- Drill 1 (Session 12) — JOIN + HAVING filter
-- Accounts with credit type that have at least one dining transaction
-- Shows total spend (all categories) and transaction count, ordered by spend

WITH grouped_data AS (
  SELECT
    a.account_name,
    t.amount,
    t.txn_id,
    m.category,
    a.account_type
  FROM `your-project.transactions_warehouse.fct_transactions` t
  LEFT JOIN `your-project.transactions_warehouse.dim_account` a
    ON t.account_id = a.account_id
  LEFT JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
  WHERE a.account_type = 'credit'
)
SELECT
  account_name,
  ROUND(SUM(amount), 0) AS total_spend,
  COUNT(txn_id) AS transaction_count
FROM grouped_data
GROUP BY account_name
HAVING SUM(CASE WHEN category = 'dining' THEN 1 ELSE 0 END) > 0
ORDER BY total_spend DESC;

-- Session 12 Drill 2 — LEFT JOIN + NULL detection
-- Accounts that have never made a grocery transaction

WITH category_field AS (
  SELECT
    t.account_id,
    t.amount,
    m.category
  FROM `project-6c41e1c3-c960-4d77-bbf.transactions_warehouse.fct_transactions` t
  LEFT JOIN `project-6c41e1c3-c960-4d77-bbf.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
),
account_field AS (
  SELECT
    a.account_name,
    a.account_type,
    SUM(c.amount) AS total_spend
  FROM `project-6c41e1c3-c960-4d77-bbf.transactions_warehouse.dim_account` a
  LEFT JOIN category_field c
    ON a.account_id = c.account_id
    AND c.category = 'groceries'
  GROUP BY a.account_name, a.account_type
)
SELECT
  account_name,
  account_type,
  CASE
    WHEN total_spend IS NULL THEN 'No Grocery Spend'
    ELSE 'Has Grocery Spend'
  END AS label
FROM account_field
ORDER BY account_name;

06/16/2026

-- Session 13 Drill 1 — 3-month moving average with DATE_TRUNC + FORMAT_DATE
-- DATE_TRUNC drives grouping/ordering, FORMAT_DATE only for display

WITH monthly_totals AS (
  SELECT
    DATE_TRUNC(d.full_date, MONTH) AS year_month,
    ROUND(SUM(t.amount), 0) AS monthly_total
  FROM `your-project.transactions_warehouse.fct_transactions` t
  LEFT JOIN `your-project.transactions_warehouse.dim_date` d
    ON t.date_id = d.date_id
  GROUP BY DATE_TRUNC(d.full_date, MONTH)
)
SELECT
  FORMAT_DATE('%Y-%m', year_month) AS y_m,
  monthly_total,
  ROUND(AVG(monthly_total) OVER (
    ORDER BY year_month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 2) AS moving_average
FROM monthly_totals
ORDER BY year_month;



