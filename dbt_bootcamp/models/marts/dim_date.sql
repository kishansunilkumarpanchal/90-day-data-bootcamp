-- dim_date
-- Grain: one row per calendar date.
-- Range: 2015-2035, generated deliberately wider than the transaction data.
--   Rationale: a missing date row causes a SILENT join failure (transactions
--   vanish on an inner join, or attributes come back NULL on a left join).
--   Extra rows cost almost nothing. Asymmetric risk -> generate wide.
--
-- Fiscal year starts April 1 (Canadian federal convention).
-- fiscal_year is named for the year it BEGINS: Apr 2025 - Mar 2026 = FY2025.
--
-- Note: this model has no ref() or source() -- the date spine is synthesized,
-- not sourced, because no upstream system owns the list of calendar dates.
-- It appears as a root node in the DAG with no incoming edges.

with dates as (

    select date_day
    from unnest(
        generate_date_array('2015-01-01', '2035-12-31', interval 1 day)
    ) as date_day

),

final as (

    select
        date_day as date_id,
        extract(year from date_day) as year,
        extract(quarter from date_day) as quarter,
        extract(month from date_day) as month_number,
        format_date('%B', date_day) as month_name,
        format_date('%A', date_day) as day_name,
        extract(dayofweek from date_day) as day_of_week,  -- BigQuery: 1 = Sunday

        extract(dayofweek from date_day) in (1, 7) as is_weekend,
        date_day = last_day(date_day) as is_month_end,

        -- Jan-Mar belong to the fiscal year that began the PREVIOUS April
        case
            when extract(month from date_day) >= 4
                then extract(year from date_day)
            else extract(year from date_day) - 1
        end as fiscal_year,

        -- April = Q1, so the fiscal quarters shift three months from calendar
        case
            when extract(month from date_day) between 4 and 6   then 1
            when extract(month from date_day) between 7 and 9   then 2
            when extract(month from date_day) between 10 and 12 then 3
            else 4
        end as fiscal_quarter

    from dates
    order by date_day

)

select * from final