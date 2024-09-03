with
--comment

source_customers as (
    select 
        id as customer_id,
        first_name as customer_first_name,
        last_name as customer_last_name
    from {{source('dbt_mallin', 'customers')}}

)

select *
from source_customers