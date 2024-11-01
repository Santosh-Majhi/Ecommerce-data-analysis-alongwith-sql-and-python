CREATE DATABASE Ecommerce;
USE Ecommerce;

-- 	Question-1 : list all unique cities where customers are located.

select distinct customer_city from customers;

-- Question-2 : count the number of orders placed in 2017.

select count(order_id) from orders
where year(order_purchase_timestamp)= 2017;

-- Question-3 : find the total sales per category.

select products.product_category as category,round(sum(payments.payment_value),2) as sales 
from products
join order_items
on products.product_id=order_items.product_id
join payments
on payments.order_id=order_items.order_id
group by category;

-- Question-4 : calculate the percentage of orders that were paid in installments.

select ((sum(case when payment_installments>=1 then 1 else 0 end) /
count(*))) * 100
from payments;

-- Question-5: count the number of customers from each state.

select customer_state, count(customer_id) from customers
group by customer_state;

-- Question-6 : calculate the number of orders per month in 2018.

select monthname(order_purchase_timestamp) as months,count(order_id) as order_count
from orders
where year(order_purchase_timestamp)=2018
group by months;

-- Question-7 : find the average number of products per order, grouped by customer city.

with count_per_order as 
(select orders.order_id,orders.customer_id,count(order_items.order_id) as order_count
 from orders
 join order_items
 on orders.order_id=order_items.order_id
 group by orders.order_id,orders.customer_id)
 
 select customers.customer_city,round(avg(count_per_order.order_count),2) as average_orders
 from customers 
 join count_per_order
 on customers.customer_id=count_per_order.customer_id
 group by customers.customer_city;
 
 
 -- Question-8 : calculate the percentage of total revenue contributed by each product category.
 
select upper(products.product_category) as category,
round((sum(payments.payment_value)/(select sum(payment_value) from payments))*100,2) 
as sales_percentage from products
join order_items
on products.product_id= order_items.product_id
join payments
on payments.order_id= order_items.order_id
group by category
order by sales_percentage desc;


-- Question-9 : identify the corelation between product price and the number of times a product has been purchased.


select products.product_category as category, count(order_items.product_id),
round(avg(order_items.price),2) from products
join order_items
on products.product_id= order_items.product_id
group by category;


-- Question-10 : calculate the total revenue generated by each seller and rank them by revenue.


select *, dense_rank() over (order by revenue desc) as rankk from
(select order_items.seller_id, sum(payments.payment_value)
as revenue from order_items
join payments
on order_items.order_id=payments.order_id
group by order_items.seller_id) as a;

-- Question-11 : calculate the moving average of order value for each customer over their order history.


select customer_id,order_purchase_timestamp, payment,
avg(payment) over(partition by customer_id order by order_purchase_timestamp
rows between 2 preceding and current row) as moving_average
from
(select orders.customer_id, orders.order_purchase_timestamp, payments.payment_value as payment
from payments
join orders
on payments.order_id= orders.order_id) as a;


-- Question-12 : calculate the cumulative sales per month for each year.


select years, months, payment, sum(payment) over(order by years, months) as cumulative_sales
from
(select year(orders.order_purchase_timestamp) as years, 
monthname(orders.order_purchase_timestamp) as months,
round(sum(payments.payment_value),2) as payment from orders
join payments
on orders.order_id= payments.order_id
group by years, months
order by years, months) as a;


-- Question-13 : calculate the year-over-year growth rate of total sales.


with a as(select year(orders.order_purchase_timestamp) as years,
round(sum(payments.payment_value),2) as payment from orders
join payments
on orders.order_id= payments.order_id
group by years
order by years)

select years,((payment - lag(payment, 1) over(order by years))/
lag(payment, 1) over(order by years))* 100 from a;


-- Question-14 : calculate the retention rate of customers, defined as the percentage of customers who make another purchase within 6 months of their first purchase.


with a as (select customers.customer_id,
min(orders.order_purchase_timestamp) as first_order
from customers
join orders
on customers.customer_id= orders.customer_id
group by customers.customer_id),

b as (select a.customer_id, count(distinct orders.order_purchase_timestamp) as next_order
from a
join orders
on orders.customer_id= a.customer_id
and orders.order_purchase_timestamp > first_order
and orders.order_purchase_timestamp < date_add(first_order,interval 6 month)
group by a.customer_id)

select 100 * (count(distinct a.customer_id)/ count(distinct b.customer_id))
from a 
left join b
on a.customer_id = b.customer_id;


-- Question-15 : identify the top 3 customers who spent the most money in each year.


select years, customer_id, payment, d_rank
from
(select year(orders.order_purchase_timestamp) as years,
orders.customer_id,
sum(payments.payment_value) as payment,
dense_rank() over(partition by year(orders.order_purchase_timestamp)
order by sum(payments.payment_value) desc) as d_rank
from orders 
join payments 
on payments.order_id = orders.order_id
group by year(orders.order_purchase_timestamp),
orders.customer_id) as a
where d_rank <=3;