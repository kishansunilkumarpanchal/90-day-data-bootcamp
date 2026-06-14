# 90-day-data-bootcamp

Building a personal finance transactions warehouse from scratch —
Python data generation, BigQuery, dbt, and AI-assisted analytics.

Stack: Python · BigQuery · dbt · Looker Studio · OpenAI API

Status: Week 3 of 12 — actively building

## Data Model

Star schema with one fact table and three dimensions:

| Table | Rows | Description |
|-------|------|-------------|
| `fct_transactions` | 500K | one row per transaction |
| `dim_date` | 366 | one row per calendar day in 2024 |
| `dim_merchant` | coming next | one row per unique merchant |
| `dim_account` | coming next | one row per account |

## Data Generation

Run the generator to produce all CSV files:

```python
python generate_transactions.py
```

Outputs: `transactions.csv`, `accounts.csv`, `dim_date.csv`

## Project Status
Phase 1 complete — full star schema built and validated.

## Architecture
```
raw_transactions (500K) ──┐
raw_accounts (100)        │
                          ▼
dim_date (366)    ──► fct_transactions (500K view)
dim_merchant (23) ──►      │
dim_account (100) ──►      │
                          ▼
                    Looker Studio + AI commentary
                         (Phase 3)
```

## How to run
1. Install Python 3.x
2. Run `python project/generate_transactions.py`
3. Upload CSVs to BigQuery as shown in the data model
4. Run `sql-drills/week-01-warehouse.sql` to build the views

---

## Progress

### Week 1 — Warehouse build (COMPLETE)
- Generated 500K synthetic transactions via Python
- Built full star schema on BigQuery (6 tables)
- Pure functions, main guard, assert-based tests in generator
- 8 drills in `sql-drills/week-01-drills.sql`

### Week 2 — SQL fluency + analytical query library (COMPLETE)
- 15 SQL drills in `sql-drills/week-02-drills.sql`
- Analytical queries covering real fintech use cases:
  - Merchant rankings by total spend
  - Month-over-month spending trends with LAG
  - Account segmentation by spending tier (CASE WHEN)
  - Top-N-per-group patterns (DENSE_RANK + PARTITION BY)
  - Running totals (SUM OVER)
  - Percentage of total company spend per account (CROSS JOIN pattern)
- Concepts learned: window functions, date functions, WHERE vs HAVING,
  multi-CTE chaining, subqueries vs CTEs, window frame defaults,
  SAFE_DIVIDE, CROSS JOIN for scalar CTEs

### Week 3 — Advanced SQL + JOIN types (IN PROGRESS)
- JOIN types: INNER, LEFT, RIGHT, FULL OUTER
- Query execution plans + performance thinking
- Moving averages and advanced window frames
- BigQuery-specific features

### Weeks 4 — Consolidation + mock interview prep (UPCOMING)

### Weeks 5-8 — dbt + analytics engineering (UPCOMING)

### Weeks 9-12 — Looker Studio + AI commentary layer (UPCOMING)

---

## Repository Structure

90-day-data-bootcamp/

├── project/

│   └── generate_transactions.py

├── sql-drills/

│   ├── week-01-warehouse.sql

│   ├── week-01-drills.sql

│   └── week-02-drills.sql

├── logs/

│   ├── LEARNING_LOG.md

│   └── CHALLENGES.md

├── notes/

│   └── star-schema-design.md

└── README.md