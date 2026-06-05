# 90-day-data-bootcamp

Building a personal finance transactions warehouse from scratch —
Python data generation, BigQuery, dbt, and AI-assisted analytics.

Stack: Python · BigQuery · dbt · Looker Studio · OpenAI API

Status: Week 1 of 12 — actively building

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

