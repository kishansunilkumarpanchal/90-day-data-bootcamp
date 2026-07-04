with transactions as (

    select * from {{ ref('stg_transactions') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['merchant_name']) }} as merchant_id,
        merchant_name,
        category

    from transactions
    group by merchant_name, category

)

select * from final