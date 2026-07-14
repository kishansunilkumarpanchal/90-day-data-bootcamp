with source as (

    select *
    from {{ source('berka_raw', 'account') }}

),

renamed_and_cleaned as (

    select
        cast(_account_id_ as int64) as account_id,

        parse_date(
            '%y%m%d',
            lpad(cast(`date` as string), 6, '0')
        ) as account_open_date,

        case trim(upper(frequency))
            when 'POPLATEK MESICNE' then 'monthly'
            when 'POPLATEK TYDNE' then 'weekly'
            when 'POPLATEK PO OBRATU' then 'after_transaction'
            else 'unknown'
        end as statement_frequency,

        cast(district_id as int64) as district_id

    from source

)

select *
from renamed_and_cleaned