# dbt Project Mental Map — North Star

## The one idea
Raw data is untrustworthy. Each layer makes it more trustworthy,
in a controlled place. Fix raw once, everything downstream heals.
That is why you layer instead of writing one flat query.

## The layers
1. Raw sources (raw_transactions, raw_accounts)
   - Untouched system exports. Never build reports directly on these —
     you don't control the column names, types, or quality.

2. Staging — views (stg_transactions, stg_accounts)
   - One stg_ model per raw table. Clean, rename, cast.
   - This is my reconciliation tab: the single controlled boundary
     where messy raw becomes predictable. Cheap views, always current.

3. Tests (attached to staging)
   - unique + not_null on keys, not_null on amount.
   - My validation checks, written as code that runs on every build.
   - They sit on staging because you validate BEFORE any business
     logic downstream depends on the data.

4. Marts — tables
   - Real business logic: joins, aggregations, the numbers management reads.
   - Built as tables (heavy, queried often — pay compute once).
   - ref() wires a mart to its staging model so dbt knows build order
     and draws the lineage graph automatically.

5. Reporting (Looker Studio) — Phase 3, on top of marts.

## The interview sentence
"I don't transform raw data in one big query — I build controlled layers,
each one making the data more trustworthy, and I test at the boundary so
nothing downstream inherits bad data. If raw ever changes, I fix one
staging model and the whole pipeline heals."