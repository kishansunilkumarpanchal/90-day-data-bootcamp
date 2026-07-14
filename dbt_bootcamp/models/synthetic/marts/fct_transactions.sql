with transactions as (

    select * from {{ ref('stg_transactions') }}

),

merchants as (

    select * from {{ ref('dim_merchant') }}

),

final as (

    select
        t.transaction_id,
        t.account_id,
        m.merchant_id,
        t.transaction_date as date_id,
        t.amount

    from transactions as t
    left join merchants as m
        on t.merchant_name = m.merchant_name

)

select * from final