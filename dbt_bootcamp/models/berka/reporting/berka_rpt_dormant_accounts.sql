with accounts as (

    select
        account_id,
        account_open_date,
        statement_frequency

    from {{ ref('berka_dim_account') }}

),

transactions as (

    select
        account_id,
        transaction_date

    from {{ ref('berka_fct_transactions') }}

),

last_activity as (

    select
        account_id,
        max(transaction_date) as last_transaction_date

    from transactions
    group by account_id

),

dormancy as (

    select
        accounts.account_id,
        accounts.account_open_date,
        accounts.statement_frequency,
        last_activity.last_transaction_date,

        case
            when last_activity.last_transaction_date is null
                then null
            else date_diff(
                date '{{ var("dataset_end_date") }}',
                last_activity.last_transaction_date,
                day
            )
        end as days_since_last_activity,

        case
            when last_activity.last_transaction_date is null
                then 'never_active'
            when date_diff(
                date '{{ var("dataset_end_date") }}',
                last_activity.last_transaction_date,
                day
            ) >= {{ var('dormancy_threshold_days') }}
                then 'dormant'
            else 'active'
        end as account_status

    from accounts
    left join last_activity
        on accounts.account_id = last_activity.account_id

)

select * from dormancy