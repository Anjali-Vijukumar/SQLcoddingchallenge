select * from project.sales;
select * from project.menu;
select * from project.members;

#1. what is the total amount of each customer spend at the restuarant?
select customer_id,
sum(price) as total_purchased_price 
from project.sales s join project.menu m on s.product_id=m.product_id 
group by customer_id;

#2. How many days each customer visited the restuarant?
select customer_id,
count(distinct(order_date)) as days_visited 
from project.sales 
group by customer_id order by days_visited desc;

#3. what was the first item from the maximum purchased by each customer?
with max_purchased as(
select s.customer_id,m.product_name, 
row_number() over(partition by s.customer_id order by s.order_date,s.product_id) as row_num
from project.sales as s join project.menu as m on s.product_id=m.product_id)
select 
customer_id,product_name 
from max_purchased where row_num=1;

#4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select * from(
select m.product_name ,row_number() over (partition by product_name ) as no_of_times_items_purchased
from project.sales as s join project.menu as m on s.product_id=m.product_id)as X 
order by X.no_of_times_items_purchased desc limit 1;

#5. Which item was the most popular for each customer?
with most_popular as
	(select s.customer_id,m.product_name,
		rank() over (partition by customer_id order by count(m.product_id) desc) as product_rank
		from sales as s
		join menu as m on s.product_id = m.product_id
		group by customer_id,product_name)
select * from most_popular where product_rank= 1;

#6. Which item was purchased first by the customer after they became a member?
with first_purchased as(
select w.product_name,w.join_date,w.order_date,w.customer_id,
rank() over(partition by join_date order by order_date) as rank_col 
from
(select b.join_date,x.*
from
(select m.product_name,s.customer_id,s.order_date,s.product_id 
from project.sales as s join project.menu as m
on s.product_id=m.product_id)as x 
join project.members as b on b.customer_id=x.customer_id 
 order by order_date) as w  
 where w.order_date>=w.join_date) 
 select customer_id,product_name,order_date,join_date from first_purchased where rank_col=1;
 
 #7. Which item was purchased just before the customer became a member.
 with first_purchased as(
select w.product_name,w.join_date,w.order_date,w.customer_id,
rank() over(partition by customer_id order by order_date desc ) as rank_col 
from
(select b.join_date,x.*
from
(select m.product_name,s.customer_id,s.order_date,s.product_id 
from project.sales as s join project.menu as m
on s.product_id=m.product_id)as x 
join project.members as b on b.customer_id=x.customer_id 
 order by order_date) as w  
 where w.order_date<w.join_date) 
 select customer_id,product_name,order_date,join_date,rank_col from first_purchased where rank_col=1  ;
 
 #8. What is the total items and amount spent for each member before they became a member?
select customer_id,count(product_id) as total_items,sum(price) as amount_spent from
(select s.customer_id,m.price,s.product_id from project.menu as m join project.sales as s 
on s.product_id=m.product_id join project.members as b on s.customer_id=b.customer_id
 where s.order_date<b.join_date)
as w group by w.customer_id order by customer_id ASC;

#9. if each $1 spent equates to 10 points and sushi has a 2x points multiplier .how many points would each customer have?
select x.customer_id,
		sum( case 
				when m.product_name= 'sushi' then (m.price*20) 
					else (m.price*10) 
			end)
                as member_points
from project.members as x join project.sales as s on s.customer_id=x.customer_id 
join project.menu as m on s.product_id=m.product_id 
group by customer_id order by customer_id ASC;

 #10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- -how many points do customer A and B have at the end of January?	

with jan_member_points as
	(select m.customer_id as customer,
			sum(case
					when s.order_date < m.join_date then
						case
							when m2.product_name = 'sushi' then (m2.price * 20)
							else (m2.price * 10)
						end
					when s.order_date > (m.join_date + 6) then 
						case
							when m2.product_name = 'sushi' then (m2.price * 20)
							else (m2.price * 10)
						end 
					else (m2.price * 20)	
				end) as member_points
		from project.members as m
		join project.sales as s on s.customer_id = m.customer_id
		join project.menu as m2 on s.product_id = m2.product_id
		where s.order_date <= '2021-01-31'
		group by customer)
select *
from jan_member_points
order by customer;

