with source as (

    select * from {{ source('raw', 'raw_accounts') }}

),

renamed as (

    select
        account_id,
        trim(account_name)       as account_name,
        trim(account_type)       as account_type
        

    from source

)

select * from renamed