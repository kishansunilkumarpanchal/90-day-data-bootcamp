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


