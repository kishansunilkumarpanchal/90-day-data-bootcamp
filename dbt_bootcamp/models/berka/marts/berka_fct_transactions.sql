with transactions as (

    select *
    from {{ ref('berka_stg_trans') }}

),

final as (

    select
        transaction_id,
        account_id,
        transaction_date,

        transaction_type,
        transaction_direction,

        amount,

        case
            when transaction_direction = 'debit'
                then amount
            else cast(0 as numeric)
        end as spend_amount,

        operation_code,
        transaction_category_code,
        

    from transactions

)

select *
from final