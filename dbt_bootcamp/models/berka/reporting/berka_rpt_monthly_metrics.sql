with transactions as (

    select *
    from {{ ref('berka_fct_transactions') }}

),

dates as (

    select
        date_id,
        year,
        month_number,
        month_name
    from {{ ref('dim_date') }}

),

monthly_metrics as (

    select
        date_trunc(dates.date_id, month) as month_start_date,
        dates.year,
        dates.month_number,
        dates.month_name,

        count(transactions.transaction_id) as transaction_count,
        count(distinct transactions.account_id) as active_accounts,
        sum(transactions.amount) as total_transaction_amount,
        sum(transactions.spend_amount) as total_spend,
        avg(transactions.amount) as average_transaction_size

    from transactions
    inner join dates
        on transactions.transaction_date = dates.date_id

    group by
        month_start_date,
        dates.year,
        dates.month_number,
        dates.month_name

)

select *
from monthly_metrics