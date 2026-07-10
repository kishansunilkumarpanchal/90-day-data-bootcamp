# Transactions Warehouse

A tested, documented analytics engineering pipeline built on **BigQuery** and **dbt Core**,
transforming 500,000 raw transactions into a validated star schema with enforced referential
integrity.

Built by a Financial Reporting Analyst applying reconciliation discipline to data engineering:
every row count reconciled to source, every foreign key proven to resolve, every assumption
tested rather than assumed.

---

## Architecture

Three layers, materializing as a star schema.

```
raw sources  ──▶  staging (views)  ──▶  marts (tables)
                       │                     │
                   validated            fct_transactions
                   at boundary          dim_account
                                        dim_merchant
                                        dim_date
```

**Raw** — untouched source tables. Never queried directly.

**Staging** — one model per source. Renames to a consistent convention, casts types
(notably `FLOAT64 → NUMERIC` on monetary amounts, because money must be exact for
reconciliation), trims whitespace, and is validated by tests before anything downstream
depends on it. Materialized as views: cheap, always current.

**Marts** — where business models live. One fact table carrying the grain, foreign keys,
and measures; three dimensions carrying descriptive attributes. Materialized as tables:
computed once, queried repeatedly.

The layering means data quality is fixed **once**, at the staging boundary. If a source
changes format, one model changes and everything downstream heals.

---

## The models

| Model | Type | Rows | Notes |
|---|---|---|---|
| `stg_transactions` | view | 500,000 | Cleaned, typed, tested |
| `stg_accounts` | view | 100 | Cleaned, typed, tested |
| `fct_transactions` | table | 500,000 | Grain: one row per transaction |
| `dim_account` | table | 100 | Grain: one row per account |
| `dim_merchant` | table | 23 | Hashed surrogate key |
| `dim_date` | table | 7,670 | Synthesized spine, 2015–2035 |

### Design decisions worth explaining

**The fact table carries keys and measures, nothing descriptive.** `merchant_name` and
`account_type` were deliberately removed and left in their dimensions. Denormalizing them
onto 500,000 rows would duplicate each value thousands of times and make reconciliation
harder — if account attributes repeat, does your total still tie?

**The surrogate key is defined once, in the dimension.** `dim_merchant` generates a hashed
`merchant_id` via `dbt_utils.generate_surrogate_key`. The fact table `ref()`s the dimension
to *fetch* that key rather than regenerating the same hash independently. Duplicating the
hashing logic in two places means that if the rule ever changes and the two drift, every
join silently returns nothing. One source of truth.

**Facts are downstream of dimensions.** Because the fact needs the dimension's manufactured
key, `dim_merchant` must build first. This inverts the naive intuition that the fact table
is "primary."

**`dim_date` is synthesized, not sourced.** No upstream system owns the list of calendar
dates, so it is generated from a date spine. The range (2015–2035) is deliberately wider
than the data: a missing date row causes a *silent* join failure — transactions vanish on
an inner join, or return `NULL` attributes on a left join — while extra rows cost almost
nothing. Asymmetric risk, so generate wide.

It carries a **fiscal calendar** (April 1 start, Canadian federal convention) alongside the
calendar one, so fiscal-period logic lives in exactly one place rather than being
re-derived — badly — in every downstream query.

---

## Testing

**20 tests, passing on every build.**

- `unique` + `not_null` on every primary key
- `not_null` on every foreign key and on `amount`
- **`relationships` tests on all three foreign keys** — every one of 500,000 transactions is
  proven to point at a merchant, an account, and a date that actually exist

That last one is the point of the project. An orphaned foreign key fails *silently*: the
transaction simply disappears from any report that joins to the dimension, and nothing warns
you. The `relationships` test is referential integrity enforced automatically on every build —
the machine version of confirming the subledger ties to the GL.

Tests run in dependency order via `dbt build`, so the pipeline **stops** rather than building
marts on top of data that failed validation.

---

## A note on the lineage graph

dbt's DAG draws **build dependencies**, not entity relationships.

`fct_transactions` refs `dim_merchant` because it needs that dimension's hashed key — a real
build dependency, so an arrow appears. It does *not* ref `dim_account` or `dim_date`, because
`account_id` and `transaction_date` already exist in staging, straight from source. No build
dependency, no arrow.

The star schema relationships are still real and enforced — they live in the `relationships`
tests, not in the graph edges. `ref()` expresses a build dependency; a foreign key expresses
a semantic relationship. They are different things.

---

## Stack

- **BigQuery** — cloud data warehouse
- **dbt Core** — transformation, testing, documentation, lineage
- **dbt_utils** — surrogate key generation
- **Python** — synthetic source data generation
- **Git / GitHub** — version control

---

## Repo structure

```
├── dbt_bootcamp/
│   ├── models/
│   │   ├── staging/          # sources.yml, stg_*.sql, tests
│   │   └── marts/            # fct_*, dim_*, tests
│   ├── packages.yml
│   └── dbt_project.yml
├── project/
│   └── generate_transactions.py
├── sql-drills/               # weekly SQL practice, written cold
├── logs/
│   ├── LEARNING_LOG.md       # what was built and why
│   └── CHALLENGES.md         # what broke, root cause, and the fix
└── notes/
```

The `CHALLENGES.md` log is deliberately public. Every bug is recorded with its root cause
and the habit that prevents it — a silent join failure, a grain violation caught by a test,
a query that returned zero rows because the logic was inverted. Debugging systematically and
writing down *why* something broke is the work.

---

## Roadmap

**Phase 3** — a Looker Studio dashboard over the marts, and an AI commentary layer that generates written analysis of spending trends directly from the warehouse.

Longer term, replacing synthetic data with real inputs (personal transaction exports, public market data) to make the pipeline handle the messiness of production sources.

---

## Context

Built by a Financial Reporting Analyst moving into analytics engineering, over roughly 90 days of structured self-directed work. An earlier iteration built the same star schema by hand in SQL; this version rebuilds it in dbt with tests, documentation, and enforced referential integrity.

The goal is to combine financial domain expertise — reconciliation, data validation, knowing when a number is wrong — with modern data tooling. Most pipeline failures are not syntax errors. They are silent correctness failures, and catching those is a discipline that transfers directly from month-end close.

## About me

Financial Reporting Analyst at a small leasing company in Canada.
Non-traditional background — self-taught through work experience.
Strong in Excel, financial reporting, reconciliations, and business problem understanding. Building modern data skills to combine finance domain expertise with analytics engineering and applied AI.

[LinkedIn](https://www.linkedin.com/in/kishansunilkumarpanchal/) | [GitHub](https://github.com/kishansunilkumarpanchal/90-day-data-bootcamp)