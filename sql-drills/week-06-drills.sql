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

- VERIFIED: 49 rows of 100 accounts — roughly half above average, which is what a symmetric spend distribution should produce. Plausibility check passed.

07/07/2026

-- ============================================================
-- Session 29 (Tuesday) — Top 3 Categories by Spend, with Merchant Counts
-- ============================================================
- PROBLEM: From fct_transactions joined to dim_merchant, return the top 3 spending categories by total amount, with the number of distinct merchants in each. Columns: category, total_spend, merchant_count. Ordered by total_spend descending.

-- VERBAL WALKTHROUGH (say this out loud in an interview):
-- "The output grain is one row per category, so I GROUP BY category. I join
--  the fact to dim_merchant on merchant_id to bring category in — an INNER
--  join, since I only want transactions that have a matching merchant.
--  Then two aggregations at that grain: SUM(amount) for total spend, and
--  COUNT(DISTINCT merchant_id) for the merchant count.
--
--  DISTINCT is essential. After joining to a 500k-row fact table, each
--  merchant appears once per transaction. A plain COUNT(merchant_id) would
--  count transactions, not merchants — returning thousands instead of a
--  handful. It would look plausible, which is the dangerous kind of wrong."
--
-- THE MISS (worth remembering):
--   Wrote correct SQL that answered a DIFFERENT question. ORDER BY sorts;
--   it does not limit. "Top 3" requires LIMIT 3. The logic was right but the
--   requirement was dropped.
--   >> Before running: reread the prompt, check off each requirement against
--      the query. Top N -> LIMIT? Sorted -> ORDER BY? All columns present? 
--   A requirements miss reads worse in an interview than a syntax error —
--   it suggests you'll confidently build the wrong thing.
--
-- STANDING REFLEX (Week 1 gap, now catching it prospectively):
--   "I have an aggregate — where's my GROUP BY, and does it list every
--    non-aggregated column?"
--
-- STYLE NOTES:
--   - COUNT(DISTINCT col) not COUNT(DISTINCT(col)). DISTINCT is a keyword
--     modifying the argument, not a function.
--   - Round at the display layer, not inside the query body.
-- ============================================================

SELECT
    m.category,
    SUM(t.amount) AS total_spend,
    COUNT(DISTINCT m.merchant_id) AS merchant_count
FROM `your-project.transactions_warehouse.fct_transactions` t
JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
GROUP BY m.category
ORDER BY total_spend DESC
LIMIT 3;

- VERIFIED: top 3 categories account for 13 of 23 total merchants. Plausible.