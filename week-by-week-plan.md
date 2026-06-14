# 90-Day Plan — Week-by-Week Reference
Started June 1 2026. Goal: finance + data + AI bridge.
Target: Canadian fintechs (Wealthsimple, Scotiabank, etc.)
Applications begin end of Week 8 (~July 25 2026)

## Phase 1 — SQL foundations + BigQuery warehouse (Weeks 1-4)

### Week 1 — COMPLETE
- Built full star schema on BigQuery (500K transactions, 6 tables)
- Python data generator (pure functions, main guard, asserts, lambdas)
- GitHub repo structure established
- 8 drills in week-01-drills.sql

### Week 2 — IN PROGRESS
- Window functions: ROW_NUMBER, DENSE_RANK, LAG (reps + bug fixes)
- Date functions: DATE_TRUNC vs EXTRACT
- WHERE vs HAVING
- Top-N-per-group pattern (PARTITION BY)
- Subquery vs CTE comparison
- CASE WHEN logic (spending tiers)
- Running totals (SUM OVER, frame defaults, explicit frames intro)
- Interview-style query explanations (2 queries practiced)
- 14 drills in week-02-drills.sql

### Week 3 — UPCOMING
- Advanced SQL: subqueries, optimization, BigQuery-specific features
- Query execution plans / basic performance thinking (parked from Week 2)
- Possibly: moving averages, more window frame practice
- Continue building analytical query library

### Week 4 — UPCOMING
- Consolidation: review all queries written Weeks 1-4
- Mock interview prep
- README polish for Phase 1 completion
- Prepare for transition to dbt

## Phase 2 — dbt + analytics engineering (Weeks 5-8)

### Week 5
- dbt Core installation
- First dbt models (staging layer)

### Week 6
- dbt staging layer deepening
- Jinja templating

### Week 7
- dbt marts + automated tests
- Python deepening (AI commentary tool hobby project begins)

### Week 8
- dbt docs
- Applications begin (~July 25 2026)

## Phase 3 — Looker Studio + AI layer (Weeks 9-12)

### Weeks 9-12
- Looker Studio dashboards
- AI commentary layer on warehouse (Python + LLM API)
- Phase 3 may incorporate real data (personal bank exports / market prices)
- Publish portfolio project

## Ongoing / Parked
- CSC — parked until after Day 90
- AI investment strategy hobby project — deferred to Week 6-7 minimum
- Python algorithm/coding practice — not a dedicated weekly track;
  covered via Week 7 hobby project and Phase 3
- Job market exploration — Sunday review slot, 15 min, NOT daily

## Key rules (unchanged since Week 1)
1. Never keep code you can't explain
2. No AI during drills — ever
3. Thursday is protected — never trade it
4. One project only — no scope creep
5. Missed sessions absorb into buffer week, never steal Thursday
6. Log conventions: LEARNING_LOG (what was built/learned),
   CHALLENGES (what tripped up and how fixed) — always separate

## Study schedule
- Mon/Tue/Wed/Fri: 6:30-7:45 PM (20-min no-AI drill, then build)
- Thursday: PROTECTED
- Saturday: 7:30 AM-12:00 PM (big build block)
- Sunday: 8:00-9:30 AM (review + mock drill + 15-min job market check-in
  + occasional README update)