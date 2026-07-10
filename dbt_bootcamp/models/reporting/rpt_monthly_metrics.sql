-- rpt_monthly_metrics
-- Grain: one row per calendar month containing transaction activity.

with transactions as (

    select
        transaction_id,
        account_id,
        date_id,
        amount

    from {{ ref('fct_transactions') }}

),

monthly_metrics as (

    select
        date_trunc(date_id, month) as month_start_date,

        count(transaction_id) as transaction_count,

        count(distinct account_id) as active_accounts,

        sum(amount) as total_spend,

        safe_divide(
            sum(amount),
            count(transaction_id)
        ) as avg_transaction_size

    from transactions
    group by date_trunc(date_id, month)

)

select
    month_start_date,
    avg_transaction_size,
    active_accounts,
    total_spend,
    transaction_count

from monthly_metrics
