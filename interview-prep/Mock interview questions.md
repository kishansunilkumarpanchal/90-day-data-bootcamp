# dbt / Analytics Engineering — Mock Interview Prep

Personal reference file. Study the **structure** of each answer as much as the content:
**headline (one sentence) → why it matters → concrete example from my project.**
That pattern works for almost any dbt question.

Project context: a BigQuery transactions warehouse, transformed with dbt Core into a
three-layer architecture (raw → staging → marts) that materializes as a star schema
(fct_transactions + dim_account + dim_merchant + dim_date), version-controlled on GitHub.

---

## Question 1 — The Architecture

**Q:** "What did you build here, and how is it structured?"

**Answer:**
I built a data warehouse using a three-layer architecture that materializes as a star
schema. The three layers are raw, staging, and marts. Raw tables are untouched — I never
build on them directly. Staging cleans and validates the data — that's where I standardize
column names, cast types, trim whitespace, and add tests to prove data quality. Marts is
where the actual business models live — that's where I build the fact table and dimensions.
The fact table carries measurements and foreign keys; the dimensions carry descriptive
attributes. They connect through those keys, forming the star. The whole point of layering
is that I fix data *once* at the staging boundary, and everything downstream — the fact,
the dimensions, any future reports — all inherit that clean foundation.

**Delivery notes (from live rep):**
- Lead with *what exists now* (the architecture), NOT the journey ("first I did Phase 1,
  then Python..."). Interviewers want the shape of what you built, not the timeline.
- No "uh" / "you know" / trailing off. One clean opening sentence, then expand.
- Layers and star schema are NOT two separate architectures — the layers are *how* you
  build the star. State that connection explicitly.

---

## Question 2 — The Staging Layer

**Q:** "Walk me through staging. Why is it a separate layer and not just part of the raw
extract or the marts?"

**Answer:**
Staging is the controlled boundary between raw data and business logic. Raw data is
fragile — column names shift, types are inconsistent, junk creeps in, and I don't control
any of it. If I built reports straight off raw, every report would have to handle that mess
individually, and if raw ever changes, everything breaks. Staging is where I own the data
quality. I rename columns to a consistent convention, cast types correctly — for instance,
I cast `amount` to `NUMERIC` instead of `FLOAT64`, because money has to be exact for
reconciliation. I trim whitespace so a "Groceries " doesn't split apart in a `GROUP BY`.
Then I test it — `unique`, `not_null`, custom checks — before anything downstream depends
on it. So a dimension or a fact table can just `ref()` staging and assume the data is clean.
If raw changes format, I fix it *once* in staging, and every downstream model heals
automatically. That's why it's separate.

---

## Question 3 — The Fact vs. Dimension Split

**Q:** "Why do you have a fact table and separate dimensions, instead of one denormalized
table with everything?"

**Answer:**
The grain is the answer. A fact table is one row per *event* — in my case, one row per
transaction. A transaction has measurements — the amount, the date — and it belongs to an
account and a merchant. A dimension is one row per *entity* — one row per account, one row
per merchant. If I flattened everything into one table, I'd repeat the account's name and
type on every transaction from that account. That's wasteful storage and it creates a
maintenance nightmare: if an account's name changes, I'd have to update thousands of rows
instead of one dimension row. More important for a financial institution — it's error-prone.
A denormalized table is hard to reconcile: does my total match source if account attributes
are duplicated? A star schema is clean: I sum the fact table's amounts — one row per
transaction, no duplication — and I join to dimensions for context. The numbers are
bulletproof because there's no hidden repetition. That's why I separate them.

---

## Question 4 — `ref()` and the DAG

**Q:** "I see you're using `ref()` in your models. What does that do, and why is it important?"

**Answer:**
`ref()` is how dbt knows one model depends on another. When I write
`{{ ref('stg_transactions') }}` inside my fact table, dbt reads that and learns "the fact
depends on staging." It does two things. First, it resolves the path — if staging moves or
the dataset name changes, every `ref()` updates automatically. I'm not hardcoding table
paths; dbt handles the plumbing. Second, and more important, it builds the DAG — the
dependency graph. dbt uses those `ref()` calls to figure out the build order automatically.
Staging has to exist before the fact can ref it, so dbt builds staging first. If I had many
models in a complex pipeline, dbt would order all of them correctly without me scripting it.
And it parallelizes — if my fact table refs staging and my dimensions also ref staging, but
the fact and dimensions don't ref each other, dbt builds the dimensions in parallel while
the fact builds, because they're independent. I never orchestrate the order by hand. That
automation is what makes dbt powerful — I declare dependencies as code, and the tool handles
the rest.

---

## The universal answer pattern

For almost any dbt / analytics-engineering question:

1. **Headline** — one clear sentence that directly answers the question.
2. **Why it matters** — the reasoning, ideally tied to data trust / reconciliation.
3. **Concrete example** — pull a real detail from this project (the `NUMERIC` cast, the
   surrogate key, the 500k→23 merchant collapse, the row-count reconciliation).

## Delivery reminders

- Lead with the answer, not the backstory.
- Cut filler words ("uh", "you know", "I would say"). Silence beats filler.
- Don't hedge. If you know it, say it plainly.
- Connect concepts instead of listing them — show you understand *why*, not just *what*.
- Use the finance framing (reconciliation, exact totals, data you can trust). It's a genuine
  edge in a fintech / bank interview and it's authentic to your background.