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