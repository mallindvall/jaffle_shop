with

orders as (
    select *
    from {{ref('staging_orders')}}

),

payments as (
    select *
    from {{ref('staging_payments')}}

),

customers as (
    select *
    from {{ref('staging_customers')}}
 
),

compleeted_payments as (
    select 
        order_id, 
        max(payment_created_date) as payment_finalized_date, 
        sum(payment_amount) as total_amount_paid
    from payments
    where payment_status <> 'fail.'
    group by 1 

),

paid_orders as (
    select 
        orders.order_id,
        orders.customer_id,
        orders.order_placed_at,
        orders.order_status,
        compleeted_payments.total_amount_paid,
        compleeted_payments.payment_finalized_date,
        customers.customer_first_name,
        customers.customer_last_name
    from orders 
    left join compleeted_payments 
        on orders.order_id = compleeted_payments.order_id
    left join customers on orders.customer_id = customers.customer_id

),

customer_orders as (
    select 
        customers.customer_id,
        min(orders.order_placed_at) as first_order_date,
        max(orders.order_placed_at) as most_recent_order_date,
        count(orders.order_id) as number_of_orders
    from customers
    left join orders
    on orders.customer_id = customers.customer_id 
    group by 1
    
),


final as (

    select
        paid_orders.order_id,
        paid_orders.customer_id,
        paid_orders.order_placed_at,
        paid_orders.order_status,
        paid_orders.total_amount_paid,
        paid_orders.payment_finalized_date,
        paid_orders.customer_first_name,
        paid_orders.customer_last_name,
        ROW_NUMBER() OVER (ORDER BY paid_orders.order_id) as transaction_seq,
        ROW_NUMBER() OVER (PARTITION BY paid_orders.customer_id ORDER BY paid_orders.order_id) as customer_sales_seq,
        case when customer_orders.first_order_date = paid_orders.order_placed_at
        then 'new'
        else 'return' end as nvsr,

        sum(paid_orders.total_amount_paid) over(partition by paid_orders.customer_id
        order by paid_orders.order_placed_at) as customer_lifetime_value,

        customer_orders.first_order_date as fdos
    from paid_orders
    left join customer_orders on paid_orders.customer_id = customer_orders.customer_id
    order by order_id

)

select * from final