# 90-Day Data Bootcamp

A structured self-directed bootcamp to transition from Financial Reporting
Analyst to Data Analyst / Analytics Engineer at Canadian fintechs and banks.

**Goal:** Become a finance + data + AI bridge — combining business domain
expertise with modern data tools to make better financial decisions.

**Target roles:** Data Analyst, Reporting Analyst, Analytics Engineer
**Target companies:** Wealthsimple, Questrade, Borrowell, Scotiabank, TD
**Applications begin:** End of Week 8 (~July 25 2026)

---

## The Plan

| Phase | Weeks | Focus | Status |
|---|---|---|---|
| Phase 1 | 1–4 | SQL foundations + BigQuery warehouse | ✅ Complete |
| Phase 2 | 5–8 | dbt + analytics engineering | 🔜 Starting Week 5 |
| Phase 3 | 9–12 | Looker Studio + AI commentary + publish | 🔜 Upcoming |

---

## Phase 1 — Complete

### What was built

A personal finance transactions warehouse on Google BigQuery using a
full star schema, built from scratch with synthetic data.

| Table | Rows | Type |
|---|---|---|
| raw_transactions | 500,000 | Raw source |
| raw_accounts | 100 | Raw source |
| dim_date | 366 | Dimension ✓ |
| dim_merchant | 23 | Dimension ✓ |
| dim_account | 100 | Dimension ✓ |
| fct_transactions | 500,000 | Fact view ✓ |

### Tech stack

- **Python** — synthetic data generation (generate_transactions.py)
  Pure functions, main guard, assert testing, lambda functions
- **BigQuery** — cloud data warehouse (free tier)
  Star schema design, validated FK relationships, dialect-specific SQL
- **Git + GitHub** — version control, public portfolio repo

### SQL concepts covered in Phase 1

**Foundations**
- GROUP BY, aggregates (SUM, COUNT, AVG, ROUND)
- INNER JOIN, LEFT JOIN — anchor table mental model
- WHERE vs HAVING — execution order distinction
- CASE WHEN — conditional logic and spend tier classification

**Window functions**
- ROW_NUMBER, DENSE_RANK, LAG
- PARTITION BY — top-N-per-group pattern
- SUM OVER — running totals with window frames
- AVG OVER — 3-month moving averages (ROWS BETWEEN)

**Date functions**
- DATE_TRUNC — monthly grouping and ordering
- FORMAT_DATE — display formatting only
- EXTRACT — pulling year/quarter/month components
- BETWEEN vs EXTRACT for partition-friendly filtering

**Advanced patterns**
- Multi-CTE chaining — one job per CTE principle
- Correlated subqueries — scalar subquery in SELECT/WHERE
- NOT EXISTS vs NOT IN — NULL safety distinction
- Self joins — duplicate pair prevention with t1.id < t2.id
- Conditional aggregation — SUM(CASE WHEN) pivot pattern
- CROSS JOIN single-row CTE — percentage of total pattern

**BigQuery-specific**
- De-correlation limitation — correlated subqueries with joins rejected
- Window functions as the production-safe alternative
- Partition pruning — BETWEEN preferred over EXTRACT for performance

### Analytical queries built (Weeks 1–4)

- Account spend ranking with percentage of total company spend
- Month-over-month spending trend with LAG + SAFE_DIVIDE
- Top-N accounts per merchant category (DENSE_RANK + PARTITION BY)
- Moving average of monthly spend (3-month trailing window)
- Accounts with no spend in a specific category (LEFT JOIN + NULL detection)
- Accounts never transacting in a category (NOT EXISTS correlated subquery)
- Most recent transaction per account (ROW_NUMBER + PARTITION BY date)
- Most recent transaction vs account average (correlated + window hybrid)
- Top 2 categories per account type by annual spend
- Q3 vs Q4 spend comparison with directional label (conditional aggregation)
- H1 vs H2 spend — accounts where second half exceeds first half
- Top 5 accounts by lifetime spend with monthly moving average
- Merchant pairs in same category (self join on dimension table)
- Transaction pairs where one amount exceeds double the other (self join)
- Months where 2+ categories exceeded 8M spend (multi-level aggregation)

---

## Repo structure

```
90-day-data-bootcamp/
├── project/
│   └── generate_transactions.py   # Python data generator
├── sql-drills/
│   ├── week-01-drills.sql         # 8 drills — foundations
│   ├── week-02-drills.sql         # 15 drills — window functions, dates
│   ├── week-03-drills.sql         # drills — subqueries, joins, self joins
│   └── week-04-drills.sql         # drills — consolidation + mock interview
├── logs/
│   ├── LEARNING_LOG.md            # What was built and learned each session
│   └── CHALLENGES.md              # What tripped up and how it was fixed
└── notes/                         # Concept summaries
```

---

## Phase 2 — Coming Week 5

- dbt Core installation and project setup
- Staging layer models
- Jinja templating
- dbt marts + automated tests
- dbt docs generation

---

## Study system

- **9–12 hours/week** across Mon/Tue/Wed/Fri evenings + Saturday morning
- **Two-track system:**
  - Track A (build sessions): AI allowed as amplifier — explain every line
  - Track B (drills): No AI, no autocomplete, blank editor, timed
- **5-step drill method:** Restate → output grain → English recipe →
  map to SQL → write and verify
- **Weekly mock interview:** verbal query walkthroughs under timed pressure

---

## About me

Financial Reporting Analyst at a small leasing company in Canada.
Non-traditional background — self-taught through work experience.
Strong in Excel, financial reporting, reconciliations, and business
problem understanding. Building modern data skills to combine finance
domain expertise with analytics engineering and applied AI.

[LinkedIn](www.linkedin.com/in/kishansunilkumarpanchal) | [GitHub](https://github.com/kishansunilkumarpanchal/90-day-data-bootcamp)