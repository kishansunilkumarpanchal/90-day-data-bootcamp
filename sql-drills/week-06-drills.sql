07/06/2026

-- ============================================================
-- Session 28 (Monday) — Accounts Above Average Total Spend
-- ============================================================
-- PROBLEM: Find every account whose total spend exceeds the average of the per-account totals. Return account_id, account_name, total_spend,
-- ordered by total_spend descending.

-- VERBAL WALKTHROUGH (say this out loud in an interview):
-- "There are two aggregation levels here, and keeping them straight is the whole problem. First I aggregate to account grain — SUM(amount) grouped by account — which gives one total_spend per account. Then I aggregate THAT result again: AVG of the per-account totals, which collapses to a single scalar value. Finally I CROSS JOIN that one-row CTE against the per-account totals, which broadcasts the single average across every row so I can compare each account against it, and filter to the ones above."


-- PRECISION NOTE: ROUND() inside the CTE means the average is computed on rounded totals. Round at the DISPLAY layer, not before you aggregate again.


WITH grouped_data AS (
    SELECT
        t.account_id,
        a.account_name,
        SUM(t.amount) AS total_spend
    FROM `your-project.transactions_warehouse.fct_transactions` t
    JOIN `your-project.transactions_warehouse.dim_account` a
        ON t.account_id = a.account_id
    GROUP BY t.account_id, a.account_name
),

total_avg_spend AS (
    SELECT AVG(total_spend) AS avg_total_spend
    FROM grouped_data
)

SELECT
    g.account_id,
    g.account_name,
    g.total_spend
FROM grouped_data g
CROSS JOIN total_avg_spend
WHERE g.total_spend > total_avg_spend.avg_total_spend
ORDER BY g.total_spend DESC;

-- VERIFIED: 49 rows of 100 accounts — roughly half above average, which is what a symmetric spend distribution should produce. Plausibility check passed.