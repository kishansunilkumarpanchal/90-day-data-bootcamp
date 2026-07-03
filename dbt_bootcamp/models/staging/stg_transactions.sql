with source as (

    select * from {{ source('raw', 'raw_transactions') }}

),

renamed as (

    select
        txn_id                   as transaction_id,
        account_id,
        trim(category)           as category,
        trim(merchant)           as merchant_name,
        cast(amount as numeric)  as amount,
        txn_date                 as transaction_date

    from source

)

select * from renamed