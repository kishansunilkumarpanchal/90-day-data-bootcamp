# Learning Log — Transactions Warehouse Project

## June 2, 2026 — Session 1

**What I built:**
- Python script that generates 500,000 realistic financial transactions
- Loaded the CSV into BigQuery as raw_transactions table
- Ran first analytical SQL query on a cloud warehouse

**What I learned:**
- timedelta does date arithmetic — START_DATE + timedelta(days=X) lands you X days forward
- MERCHANTS dictionary chains with category so merchants always match their category
- Random data clusters visually but GROUP BY proves it's evenly distributed

## June 3, 2026 — Session 2

**What I built:**
- Added generate_accounts() function to the Python script
- Loaded accounts.csv into BigQuery as raw_accounts table
- Wrote first real JOIN query across two tables in BigQuery

**What I learned:**
- I learnt writing CASE WHEN syntax in SQL plus revised the DATE function DATE_TRUNC and DATE_SUB to run in BigQury.

**BigQuery syntax rules to remember:**
DATE_TRUNC(CURRENT_DATE, MONTH) DATE_TRUNC(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH) DATE_TRUNC(DATE_ADD(CURRENT_DATE, INTERVAL 1 MONTH)
