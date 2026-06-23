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
  FROM `your-project.transactions_warehouse.fct_transactions` t
  LEFT JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
),
account_field AS (
  SELECT
    a.account_name,
    a.account_type,
    SUM(c.amount) AS total_spend
  FROM `your-project.transactions_warehouse.dim_account` a
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

06/17/2026

-- Session 14 Drill 1 — Top spending category per account, with tie handling
-- DENSE_RANK preserves ties; ROW_NUMBER would arbitrarily drop tied categories

WITH category_totals AS (
  SELECT
    t.account_id,
    m.category,
    ROUND(SUM(t.amount), 0) AS total_spend
  FROM `your-project.transactions_warehouse.fct_transactions` t
  LEFT JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
  GROUP BY t.account_id, m.category
),
account_data AS (
  SELECT
    a.account_name,
    c.category,
    c.total_spend,
    DENSE_RANK() OVER (PARTITION BY a.account_name ORDER BY c.total_spend DESC) AS rnk
  FROM category_totals c
  LEFT JOIN `your-project.transactions_warehouse.dim_account` a
    ON c.account_id = a.account_id
)
SELECT account_name, category, total_spend, rnk
FROM account_data
WHERE rnk = 1
ORDER BY total_spend DESC;


-- Session 14 Drill 2 — Accounts with no grocery spend, via correlated NOT EXISTS
-- Same result as Session 12's LEFT JOIN + NULL check version, different mechanism

SELECT a.account_name, a.account_type
FROM `your-project.transactions_warehouse.dim_account` a
WHERE NOT EXISTS (
  SELECT 1
  FROM `your-project.transactions_warehouse.fct_transactions` t
  LEFT JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
  WHERE t.account_id = a.account_id
    AND m.category = 'groceries';

06/21/2026

-- Session 15 Drill 1 — Correlated subquery: accounts whose highest transaction
-- exceeds the overall dataset average transaction amount

WITH account_max AS (
  SELECT
    a.account_name,
    a.account_type,
    (SELECT MAX(t.amount)
     FROM `your-project.transactions_warehouse.fct_transactions` t
     WHERE t.account_id = a.account_id) AS highest_txn
  FROM `your-project.transactions_warehouse.dim_account` a
)
SELECT account_name, account_type, highest_txn
FROM account_max
WHERE highest_txn > (SELECT AVG(amount) 
                     FROM `your-project.transactions_warehouse.fct_transactions`);



