07/14/2026

-- week-06-drills.sql
-- Dormant account ranking: txn count, most recent txn, days since last activity
--
1. Restate: For every account, I need to know how many transactions they've made in total, when their last transaction happened, and how long it's been since then relative to the end of the dataset.
2. Output grain: One row per account_id. That immediately tells me I need GROUP BY account_id and every non-grouped column has to be wrapped in an aggregate.
3. English recipe: Start from the transactions table. For each account, count the transactions, find the latest transaction date, and calculate the gap between that date and the fixed dataset end-date of 1998-12-31. Sort so the longest-dormant accounts come first.
4. Map to SQL: "Count the transactions" → COUNT(transaction_id). "Find the latest date" → MAX(transaction_date). "Gap between two dates" → DATE_DIFF(end, latest, DAY), ordered later-date-first so the result is positive. "One row per account" → GROUP BY account_id. "Longest-dormant first" → ORDER BY dormant_days DESC.
--

SELECT
  account_id,
  COUNT(transaction_id) AS txn_count,
  MAX(transaction_date) AS most_recent_txn,
  DATE_DIFF(DATE '1998-12-31', MAX(transaction_date), DAY) AS dormant_days
FROM `your-project.dbt_dev.berka_stg_trans`
GROUP BY account_id
ORDER BY dormant_days DESC;



