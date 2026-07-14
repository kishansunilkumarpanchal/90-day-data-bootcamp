with source as (

    select *
    from {{ source('berka_raw', 'trans') }}

),

renamed_and_cleaned as (

    select
        _trans_id_ as transaction_id,
        cast(account_id as int64) as account_id,

        parse_date(
            '%y%m%d',
            lpad(cast(`date` as string), 6, '0')
        ) as transaction_date,

        case trim(upper(`type`))
            when 'PRIJEM' then 'credit'
            when 'VYDAJ' then 'withdrawal'
            when 'VYBER' then 'cash_withdrawal'
            else 'unknown'
        end as transaction_type,

        case trim(upper(`type`))
            when 'PRIJEM' then 'credit'
            when 'VYDAJ' then 'debit'
            when 'VYBER' then 'debit'
            else 'unknown'
        end as transaction_direction,

        nullif(trim(operation), '') as operation_code,
        nullif(trim(k_symbol), '') as transaction_category_code,

        cast(amount as numeric) as amount,
        cast(balance as numeric) as account_balance,

        nullif(trim(bank), '') as counterparty_bank_code,
        nullif(trim(cast(`account` as string)), '') as counterparty_account_id

    from source

)

select *
from renamed_and_cleaned