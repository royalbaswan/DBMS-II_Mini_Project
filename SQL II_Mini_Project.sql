-- Composite data of a business organisation, confined to ‘sales and delivery’ domain is given for the period of last decade.
--  From the given data retrieve solutions for the given scenario.

-- Q1) Join all the tables and create a new table called combined_table.
-- (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
create database sqlminiproject2;
use sqlminiproject2;

create table combined_table (
select cd.cust_id, customer_name, province, region, Customer_Segment, 
mf.ord_id, mf.prod_id, sales, discount, order_quantity, profit, Shipping_Cost, Product_Base_Margin,
od.Order_ID, Order_Date, order_priority, 
Product_category, product_sub_category,
sd.Ship_id, ship_date, ship_mode
from cust_dimen cd inner join market_fact mf on cd.cust_id=mf.Cust_id 
inner join orders_dimen od on od.Ord_id=mf.ord_id 
inner join prod_dimen pd on pd.prod_id=mf.prod_id
inner join shipping_dimen sd on sd.ship_id=mf.ship_id);



-- Q2) Find the top 3 customers who have the maximum number of orders.
select  c.cust_id, customer_name, sum(Order_quantity) no_of_orders
from cust_dimen c inner join market_fact m on c.cust_id=m.Cust_id
group by c.cust_id, Customer_Name
order by sum(Order_quantity) desc
limit 3;
 
 
-- Q3) Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
set sql_safe_updates=0;
update orders_dimen set order_date= str_to_date(order_date, '%d-%m-%Y') ;
alter table orders_dimen modify order_date date;

update shipping_dimen set ship_date= str_to_date(ship_date, '%d-%m-%Y') ;
alter table shipping_dimen modify ship_date date;	


select *, datediff( ship_date,order_date) DaysTakenForDelivery 
from orders_dimen od inner join shipping_dimen sd on od.order_id=sd.Order_ID;


-- Q4) Find the customer whose order took the maximum time to get delivered.
select * from orders_dimen;
select * from shipping_dimen;

select Customer_Name, max(datediff(Ship_Date,Order_Date)) daystakenfordelivery
from orders_dimen od inner join shipping_dimen sd on od.order_id=sd.Order_id  inner join 
market_fact mf on mf.ord_id=od.ord_id inner join cust_dimen cd on cd.cust_id=mf.Cust_id
group by Customer_Name 
order by daystakenfordelivery desc
limit 1;


-- Q5)Retrieve total sales made by each product from the data (use Windows function).

select distinct Prod_id, sum(sales) over(partition by prod_id) total_sales
from market_fact ;

-- Other Way
select prod_id, sum(sales) 
from market_fact
group by prod_id;

-- Q6) Retrieve total profit made from each product from the data (use windows function)

select distinct Prod_id, sum(profit) over(partition by prod_id) total_profit
from market_fact ;


-- Q7) Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011

select year(order_date), month(order_date), count(cd.cust_id)
from cust_dimen cd inner join market_fact mf on cd.cust_id=mf.cust_id
inner join orders_dimen od on od.Ord_id=mf.ord_id
where year(order_date)=2011 and month(Order_Date)=01
group by year(order_date), month(order_date)
order by month(order_date);

-- Other Way
select year(order_date), month(order_date), count(cust_id) over(partition by year(Order_Date) order by month(Order_Date)) as total_unique_customers
from combined_table
where year(order_date)=2011 and cust_id in 
(select cust_id from combined_table
where year(order_date)=2011 and month(Order_Date)=01);

--  Q8) Retrieve month-by-month customer retention rate since the start of the business.(using views)
Create view Visit_log AS 
SELECT cust_id, TIMESTAMPDIFF(month,'2009-01-01', order_date) AS visit_month
FROM combined_table
GROUP BY 1,2
ORDER BY 1,2;
  
Create view Time_Lapse AS 
SELECT distinct cust_id, visit_month, lead(visit_month, 1) 
over(partition BY cust_id ORDER BY cust_id, visit_month) led
FROM Visit_log;    
    
Create view time_lapse_calculated as 
SELECT cust_id, visit_month, led, led-visit_month AS time_diff from Time_Lapse;

Create view customer_category as 
SELECT cust_id, visit_month, 
CASE WHEN time_diff=1 THEN "retained"
WHEN time_diff>1 THEN "irregular"
WHEN time_diff IS NULL THEN "churned"
END as cust_category
FROM time_lapse_calculated;

SELECT visit_month,(COUNT(if (cust_category="retained",1,NULL))/COUNT(cust_id)) AS retention
FROM customer_category GROUP BY 1 order by visit_month asc;

-- Tips: 
#1: Create a view where each user’s visits are logged by month, allowing for the possibility that these will have occurred over multiple # years since whenever business started operations
# 2: Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.
# 3: Calculate the time gaps between visits
# 4: categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned
# 5: calculate the retention month wise

