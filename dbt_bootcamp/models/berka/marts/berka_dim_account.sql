-- berka_dim_account
-- Grain: one row per account.
-- Key: account_id, used directly (already unique + single-column from source).
-- No surrogate key needed -- see reasoning: source already identifies the grain.

with account as (

    select *
    from {{ ref('berka_stg_account') }}

),

final as (

    select
        account_id,
        district_id,
        account_open_date,
        statement_frequency

    from account

)

select * from final