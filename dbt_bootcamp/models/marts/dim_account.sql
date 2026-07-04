with accounts as (

    select * from {{ ref('stg_accounts') }}

),

final as (

    select
        account_id,
        account_name,
        account_type

    from accounts

)

select * from final