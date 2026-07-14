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

07/08/2026

-- ============================================================
-- Session 30 (Wednesday) — Spend by Fiscal Quarter, FY2024
-- ============================================================
-- PROBLEM: From fct_transactions joined to dim_date, return total spend and
-- transaction count by fiscal quarter for fiscal year 2024.
-- Columns: fiscal_quarter, total_spend, transaction_count. Ordered by quarter.
--
-- VERBAL WALKTHROUGH (say this out loud in an interview):
-- "Output grain is one row per fiscal quarter, so I GROUP BY fiscal_quarter.
--  I join the fact to dim_date on date_id — the date itself is the key, so no
--  cast or lookup needed. I filter on fiscal_year, NOT calendar year: that's
--  the whole reason the date dimension carries a fiscal calendar. Then two
--  aggregations at that grain — SUM(amount) and COUNT(*)."


SELECT
    d.fiscal_quarter,
    SUM(t.amount) AS total_spend,
    COUNT(*) AS transaction_count
FROM `your-project.dbt_dev.fct_transactions` t
JOIN `your-project.dbt_dev.dim_date` d
    ON t.date_id = d.date_id
WHERE d.fiscal_year = 2024
GROUP BY d.fiscal_quarter
ORDER BY d.fiscal_quarter;

-- VERIFIED: 3 rows (FY2024 Q1-Q3). Q4 absent — no 2025 source data. Correct.

07/11/2026

-- ============================================================
-- Session 32 (Saturday) — Category Spend Pivot by Account Type
-- ============================================================
-- PROBLEM: For each account_type, show total groceries spend and total dining
-- spend as TWO SEPARATE COLUMNS in one row. Columns: account_type, groceries_spend, dining_spend. Ordered by account_type.
--
-- VERBAL WALKTHROUGH (say this out loud in an interview):
-- "This is conditional aggregation — a pivot. The grain is one row per
--  account_type, so I GROUP BY account_type. To put groceries and dining in
--  SEPARATE columns rather than stacked rows, I use SUM(CASE WHEN category =
--  X THEN amount ELSE 0 END) once per category. For any given transaction,
--  only one CASE matches; the others return 0, so each transaction's amount
--  lands in exactly one column. The ELSE 0 is what lets a row contribute to
--  one column while staying neutral in the others."

-- ============================================================

SELECT
    a.account_type,
    SUM(CASE WHEN m.category = 'groceries' THEN t.amount ELSE 0 END) AS groceries_spend,
    SUM(CASE WHEN m.category = 'dining'    THEN t.amount ELSE 0 END) AS dining_spend
FROM `your-project.transactions_warehouse.fct_transactions` t
JOIN `your-project.transactions_warehouse.dim_account` a
    ON t.account_id = a.account_id
JOIN `your-project.transactions_warehouse.dim_merchant` m
    ON t.merchant_id = m.merchant_id
GROUP BY a.account_type
ORDER BY a.account_type;