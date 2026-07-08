07/02/2026

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

07/03/2026


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

07/04/2026

-- ============================================================
-- Session 26 (Saturday) — Largest Transaction Per Account (Window Function)
-- ============================================================
-- PROBLEM: From fct_transactions, return each account's single largest
-- transaction — one row per account. Columns: txn_id, account_id, amount.
--
-- VERBAL WALKTHROUGH (say this out loud in an interview):
-- "I need one row per account, so I use ROW_NUMBER partitioned by
--  account_id, ordered by amount descending — rank 1 is each account's
--  largest transaction. I can't filter on the rank in the same SELECT
--  where I define it, because WHERE runs before the window function
--  exists, so I wrap the ranking in a CTE and filter rnk = 1 in the
--  outer query. I add txn_id ASC as a tiebreaker so the result is
--  deterministic — otherwise ROW_NUMBER breaks ties arbitrarily and
--  the query isn't reproducible run to run."
--
-- GRAIN NOTE (the key decision):
--   ROW_NUMBER  -> exactly one row per account (ties broken by tiebreaker)
--   RANK        -> keeps ALL rows tied for the max (same as a correlated
--                  subquery with amount = MAX)
--   Choice of function IS the grain decision, not just syntax.
--
-- TRAP AVOIDED: cannot reference the window alias (rnk) in WHERE of the
-- same SELECT — must wrap in a CTE first.
-- ============================================================

WITH ranked_data AS (
    SELECT
        txn_id,
        account_id,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY account_id
            ORDER BY amount DESC, txn_id ASC   -- txn_id = deterministic tiebreaker
        ) AS rnk
    FROM `your-project.transactions_warehouse.fct_transactions`
)
SELECT
    txn_id,
    account_id,
    amount
FROM ranked_data
WHERE rnk = 1
ORDER BY account_id;

07/05/2026

-- ============================================================
-- Session 27 (Sunday) — Accounts With No Grocery Transactions (Absence Query)
-- ============================================================
-- PROBLEM: Find every account that has NEVER transacted in the 'Groceries'
-- category. Return account_id and account_name, ordered by account_id.
--
-- VERBAL WALKTHROUGH (say this out loud in an interview):
-- "This is an absence question, so the anchor table has to be the FULL set
--  of accounts — dim_account — and I subtract the ones that match. I start
--  from every account and keep it only if NOT EXISTS a grocery transaction
--  for that account_id. The correlated link WHERE t.account_id = a.account_id
--  is what ties the subquery to each outer account row.
--
--  I use NOT EXISTS rather than NOT IN because NOT IN is unsafe with NULLs:
--  if the subquery returns even one NULL, every comparison evaluates to
--  UNKNOWN and the query silently returns zero rows. NOT EXISTS handles
--  NULLs correctly. A LEFT JOIN with an IS NULL check also works, but with
--  two joins here NOT EXISTS reads cleaner."
--
-- THE TRAP I FELL INTO (worth remembering):
--   Wrong approach: COUNT grocery transactions per account, then filter
--   COUNT = 0. This ALWAYS returns zero rows — filtering to grocery
--   transactions first means accounts with no groceries have no rows in the
--   CTE at all. They don't get a count of 0; they get no row.
--   >> You cannot count something that isn't there. 
--   Rule: for absence questions, anchor on the FULL set and subtract matches.
--   Never count within a filtered set and look for zero.

-- ============================================================

SELECT
    a.account_id,
    a.account_name
FROM `your-project.transactions_warehouse.dim_account` a
WHERE NOT EXISTS (
    SELECT 1
    FROM `your-project.transactions_warehouse.fct_transactions` t
    JOIN `your-project.transactions_warehouse.dim_merchant` m
        ON t.merchant_id = m.merchant_id
    WHERE t.account_id = a.account_id
      AND m.category = 'Groceries'
)
ORDER BY a.account_id;