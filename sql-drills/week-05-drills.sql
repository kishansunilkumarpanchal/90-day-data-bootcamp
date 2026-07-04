-- Drill: Same-account, same-day transaction pairs where one amount > 3x the other
-- Session 23, Track B (self joins)

/*
1. Restate: Find pairs of transactions on the same account and same day where 
   one amount is more than 3x the other, with no duplicate or mirrored pairs.
2. Output grain: One row = one qualifying transaction pair. 
   Columns: account_id, date_id, amount (larger side), theree_x_amount (smaller side).
3. Recipe: Join fct_transactions to itself on matching account_id and date_id. 
   Keep only rows where the ratio of one amount to the other exceeds 3, 
   and use txn_id comparison to keep each pair only once.
4. Mapping: Self join on account_id + date_id -> filter with SAFE_DIVIDE ratio > 3 
   -> dedupe with txn_id inequality -> order by account_id, date_id.
5. Verbal reasoning: If SAFE_DIVIDE(t1.amount, t2.amount) > 3, the reversed ratio 
   SAFE_DIVIDE(t2.amount, t1.amount) must be less than 1/3, so it can never also 
   satisfy > 3 — the condition is directionally asymmetric, which prevents mirror 
   duplicates. The t1.txn_id > t2.txn_id condition is a separate, identity-based 
   dedup mechanism (not business logic) that prevents a transaction from pairing 
   with itself and ensures each valid pair appears exactly once.
*/

SELECT 
  t1.account_id, 
  t1.date_id, 
  t1.amount, 
  t2.amount AS theree_x_amount
FROM `your-project.transactions_warehouse.fct_transactions` t1
JOIN `your-project.transactions_warehouse.fct_transactions` t2
  ON t1.account_id = t2.account_id 
  AND t1.date_id = t2.date_id
WHERE SAFE_DIVIDE(t1.amount, t2.amount) > 3
  AND t1.txn_id > t2.txn_id
ORDER BY t1.account_id, t1.date_id;


-- ============================================================
-- Session 24 (Wednesday) — Correlated Subquery Drill
-- ============================================================
-- PROBLEM: From fct_transactions, find every transaction whose
-- amount is greater than the average amount for that transaction's
-- OWN account. One row per qualifying transaction.
-- Output: txn_id, account_id, amount.
--
-- VERBAL WALKTHROUGH (say this out loud in an interview):
-- "This is a correlated subquery. The outer query scans each
--  transaction as t1. For each row, the inner query computes the
--  average amount for THAT row's specific account — the link line
--  WHERE t2.account_id = t1.account_id is what makes it correlated,
--  because the inner query depends on the outer row's account_id.
--  I keep only transactions whose amount beats their own account's
--  average. Aliases t1 (outer) and t2 (inner) must be distinct so
--  the correlation can reference the outer row."
--
-- INTERVIEW FOLLOW-UP ("make it faster?"):
-- A correlated subquery conceptually re-runs the inner query once
-- per outer row. The window-function version does it in a single
-- pass: AVG(amount) OVER (PARTITION BY account_id), then compare.

-- ============================================================

SELECT t1.txn_id, t1.account_id, t1.amount
FROM `your-project.transactions_warehouse.fct_transactions` t1
WHERE t1.amount > (
    SELECT AVG(t2.amount)
    FROM `your-project.transactions_warehouse.fct_transactions` t2
    WHERE t2.account_id = t1.account_id
)
ORDER BY t1.account_id, t1.amount DESC;