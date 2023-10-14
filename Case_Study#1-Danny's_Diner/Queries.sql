--Table Creation
create table Sales(
customer_id char, order_date date, product_id int);

Create table Menu(
product_id int, product_name varchar, price int);

Create table Members(
customer_id char, join_date date);

--Value Insertion
copy Sales from 
'C:\Users\sk757\Downloads\Data Analyst\SQl Pj\8 weeks SQL challenge\Case study#1 - Dannys Diner\sales.csv' delimiter ','
csv header;

copy Menu from 
'C:\Users\sk757\Downloads\Data Analyst\SQl Pj\8 weeks SQL challenge\Case study#1 - Dannys Diner\menu.csv' delimiter ','
csv header;

copy Members from 
'C:\Users\sk757\Downloads\Data Analyst\SQl Pj\8 weeks SQL challenge\Case study#1 - Dannys Diner\members.csv' delimiter ','
csv header;

select * from sales, menu, members;

                            /* Case Study Questions */
--What is the total amount each customer spent at the restaurant?
select a.customer_id, sum(b.price) as total_amount from sales as a
join menu as b
on a.product_id = b.product_id
group by a.customer_id
order by total_amount desc;

--How many days has each customer visited the restaurant ?
select customer_id, count(order_date) as days_visited from sales
group by customer_id
order by days_visited;

--What was the first item from the menu purchased by each customer?
select a.customer_id, b.product_name, a.order_date from sales as a
join menu as b
on a.product_id = b.product_id 
where  a.order_date = (select min(order_date) from sales)
group by a.customer_id, b.product_name, a.order_date
order by customer_id
;

--What is the most purchased item on the menu and how many times was it purchased by all customers?


with cte as (
select a.customer_id, b.product_name, count(b.product_id) as how_many_times from sales a
join menu b
on a.product_id = b.product_id
group by a.customer_id, b.product_name ) 

select customer_id, product_name, max(how_many_times) as how_many_times from cte
group by customer_id, product_name
order by  how_many_times desc, customer_id desc
limit 3
;
              /* OR */

select  c.customer_id, c.product_name, max(c.how_many_times) as how_many_times  from sales as d
join (
 select a.customer_id, b.product_id, b.product_name, count(b.product_id) as how_many_times from sales a
 join menu b
 on a.product_id = b.product_id
 group by a.customer_id, b.product_id, b.product_name
    ) as c
on c.product_id = d.product_id
group by  c.customer_id, c.product_name
order by how_many_times desc, c.customer_id desc
limit 3;

--Which item was the most popular for each customer?

select  c.customer_id, c.product_name as most_popular, max(c.how_many_times) as how_many_times  from sales as d
join (
 select a.customer_id, b.product_id, b.product_name, count(b.product_id) as how_many_times from sales a
 join menu b
 on a.product_id = b.product_id
 group by a.customer_id, b.product_id, b.product_name
    ) as c
on c.product_id = d.product_id
group by  c.customer_id, c.product_name
order by how_many_times desc, c.customer_id desc
limit 3

--Which item was purchased first by the customer after they became a member?


select d.customer_id, d.product_name, c.join_date from members as c
join(
 select a.customer_id, b.product_name, a.order_date from sales as a
 join menu as b
 on a.product_id = b.product_id 
 where  a.order_date = (select min(order_date) from sales)
 group by a.customer_id, b.product_name, a.order_date
   ) as d
on c.customer_id = d.customer_id

--Which item was purchased just before the customer became a member?

select a.customer_id, b.product_name, a.order_date as before_customer_became_member from sales as a
join menu as b
on a.product_id = b.product_id 
where (a.customer_id, a.order_date) not in (select customer_id, join_date from members)
group by a.customer_id, b.product_name, a.order_date
order by customer_id

--What is the total items and amount spent for each member before they became a member? 

select a.customer_id, b.product_name, sum(b.price) as amount,a.order_date as before_customer_became_member from sales as a
join menu as b
on a.product_id = b.product_id 
where (a.customer_id, a.order_date) not in (select customer_id, join_date from members)
group by a.customer_id, b.product_name, a.order_date
order by customer_id

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select a.customer_id, sum(b.price) as total_amount, sum(case
  when product_name = 'sushi' then price*20
  else price*10
  end) as points from sales as a
join menu as b
on a.product_id = b.product_id
group by a.customer_id
order by total_amount desc

--In the first week after a customer joins the program (including their join date), 
--they earn 2x points on all items, not just sushi - how many points do customer
--A and B have at the end of January?

select d.customer_id, d.points, d.order_date,c.join_date from members as c
right join (
select a.customer_id, sum(b.price*20) as points, a.order_date  from sales as a
join menu as b
on a.product_id = b.product_id
where order_date > '2021-01-07'
group by a.customer_id,a.order_date) as d
on c.customer_id = d.customer_id

                          /* Bonus Questions*/
--Join All The Things
select d.customer_id, d.order_date, d.product_name, d.price, case 
 when d.order_date >= c.join_date and c.customer_id = d.customer_id then 'Y'
 else 'N' end as member from members as c
right join 
(select a.customer_id, a.order_date, b.product_name, b.price from sales as a 
join menu as b
on a.product_id = b.product_id) as d
on c.customer_id = d.customer_id
order by d.customer_id;

                                 /* Rank All The Things */
with cte as(
select d.customer_id, d.order_date, d.product_name, d.price, case 
 when d.order_date >= c.join_date and c.customer_id = d.customer_id then 'Y'
 else 'N' end as member from members as c
right join 
(select a.customer_id, a.order_date, b.product_name, b.price from sales as a 
join menu as b
on a.product_id = b.product_id) as d
on c.customer_id = d.customer_id
order by d.customer_id)


select *, case 
when member = 'Y' then dense_rank() over(partition by member,customer_id order by order_date)
end as rank
from cte
order by customer_id, order_date
