# 90-Day Data Bootcamp — Project Context

## Who I am
Financial Reporting Analyst at a small leasing company in Canada.
Non-traditional background, self-taught through work experience.
Transitioning into analytics engineering and data roles.
Target companies: Wealthsimple, Scotiabank, Canadian fintechs.

## Career goal
Become a finance + data + AI bridge — not a pure software engineer.
Combine business understanding, SQL, Python, dbt, cloud warehouses,
and applied AI to make better financial and business decisions.

## Current technical level
- Strong: Excel, financial reporting, reconciliations, 
  stakeholder communication, business problem understanding
- Intermediate: SQL (improving rapidly), Python (improving)
- Beginner: dbt, BigQuery, cloud platforms, Power BI, AI development

## The 90-day plan
Three phases, 9-12 hrs/week, started June 1 2026:
- Phase 1 (Weeks 1-4): SQL foundations + BigQuery warehouse
- Phase 2 (Weeks 5-8): dbt + analytics engineering
- Phase 3 (Weeks 9-12): Looker Studio + AI commentary + publish

Applications begin end of Week 8 (around July 25 2026).
CSC parked until after 90 days.

## Current status — PHASE 1 COMPLETE (End of Week 1)

### What's been built
Transactions warehouse on BigQuery — full star schema:

| Table | Rows | Type |
|-------|------|------|
| raw_transactions | 500,000 | raw source |
| raw_accounts | 100 | raw source |
| dim_date | 366 | dimension ✓ |
| dim_merchant | 23 | dimension ✓ |
| dim_account | 100 | dimension ✓ |
| fct_transactions | 500,000 | fact view ✓ |

### Tech stack
- Python — data generation (generate_transactions.py)
- BigQuery — cloud data warehouse (free tier)
- Git + GitHub — version control
- dbt — coming Phase 2 (Week 5)
- Looker Studio — coming Phase 3 (Week 9)

### GitHub repo
https://github.com/kishansunilkumarpanchal/90-day-data-bootcamp

Repo structure:
- project/ — Python scripts
- sql-drills/ — weekly SQL practice queries
- logs/ — LEARNING_LOG.md and CHALLENGES.md
- notes/ — concept summaries

## SQL skill level now
- GROUP BY, aggregates, JOINs — solid
- Window functions (ROW_NUMBER, RANK, DENSE_RANK, LAG) — understands
  approach, syntax needs reps
- CTEs — understands execution order, can write from scratch
- Date functions (DATE_TRUNC, EXTRACT, FORMAT_DATE) — learning
- Star schema queries — can write end-to-end
- Gap: finishing queries completely without missing GROUP BY/ORDER BY

## Python skill level now
- Can write generators, loops, functions from scratch
- Understands pure functions, main guard, assert testing
- Lambda functions — just learned
- Gap: syntax recall under pressure, autocomplete dependency reducing

## Two-track system
- Track A (project/build mode): AI allowed as amplifier,
  explain every line before keeping it
- Track B (drills/practice mode): no AI, no autocomplete,
  blank editor, 20 min at start of every weekday session

## Study schedule
- Mon/Tue/Wed/Fri: 6:30-7:45 PM (drill first 20 min, then project)
- Thursday: PROTECTED — no study (time with wife)
- Saturday: 7:30 AM-12:00 PM (big build block)
- Sunday: 8:00-9:30 AM (review + one mock drill)
- 9:30 PM weekdays: hard stop reminder

## Key rules established
1. Never keep code you can't explain
2. No AI during drills — ever
3. Thursday is protected — never trade it
4. One project only — no scope creep
5. Missed sessions absorb into buffer week, never steal Thursday
6. CSC parked until after 90 days
7. No Spark/Hadoop — modern stack only (BigQuery + dbt)

## Log conventions
- LEARNING_LOG.md: what was built, concepts learned, syntax rules
- CHALLENGES.md: what tripped up and how it was fixed
  (always separate, always honest)

## What's coming next
- Sunday June 8: weekly review + cold timed drill + README update
- Week 2-4: more complex star schema queries + deeper SQL fluency
- Week 5: dbt Core installation + first models
- Week 6: dbt staging layer
- Week 7: dbt marts + automated tests
- Week 8: dbt docs + applications begin

## Diagnostic results (from first session)
SQL: logic strong, finishing habit (GROUP BY, ORDER BY,
table aliases) needs drilling. Window function awareness present.
Python: logic sound, syntax from memory needs reps.
Core gap: generation vs recognition — can explain code,
struggles to produce it cold under pressure.

## Mentor instructions
- Call out distraction reflex immediately
- Enforce no-AI rule during drills strictly  
- Never let Thursday get traded
- Test understanding before moving forward
- Separate log formats: learning log vs challenges log
- Push back on "shiny new project" ideas
- Hold the line on one project at a time
- Remind of opportunity cost when scope creeps