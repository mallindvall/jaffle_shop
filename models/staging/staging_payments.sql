with

source_payments as (
    select 
        id as payment_id,
        orderid as order_id,
        created as payment_created_date,
        status as payment_status,
        amount/100.0 as payment_amount,
        paymentmethod as payment_method
    from {{source('dbt_mallin', 'payments')}}
)

select *
from source_payments