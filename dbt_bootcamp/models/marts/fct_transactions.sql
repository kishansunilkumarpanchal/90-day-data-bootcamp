with transactions as (

    select * from {{ ref('stg_transactions') }}

),

accounts as (

    select * from {{ ref('stg_accounts') }}

),

final as (

    select
        t.transaction_id,
        t.account_id,
        a.account_type,
        t.category,
        t.merchant_name,
        t.transaction_date,
        t.amount

    from transactions as t
    left join accounts as a
        on t.account_id = a.account_id

)

select * from final