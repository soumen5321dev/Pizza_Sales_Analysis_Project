/*
SQL Case Study Project
*/

CREATE DATABASE pizza_project;
USE pizza_project;

DROP DATABASE pizza_project;

-- Now understand each table (all columns)
SELECT * FROM order_details; -- order_details_id	order_id	pizza_id	quantity

SELECT * FROM orders; -- order_id, 	date, 	time

SELECT * FROM pizza_types; -- pizza_type_id, name, category, ingredients

SELECT * FROM pizzas; -- pizza_id, pizza_type_id, size, price

-- Basic Questions
-- Retrieve the total number of orders placed.
SELECT COUNT(DISTINCT order_id) AS Total_Orders FROM orders;

-- Calculate the total revenue generated from pizza sales.
SELECT order_details.pizza_id, order_details.quantity, pizzas.price
FROM order_details
JOIN pizzas
ON pizzas.pizza_id = order_details.pizza_id;

-- to get the answer
SELECT CAST(SUM(order_details.quantity * pizzas.price) AS DECIMAL(10,2)) AS Total_Revenue
FROM order_details
JOIN pizzas
ON pizzas.pizza_id = order_details.pizza_id;

-- Identify the highest-priced pizza.
-- Using LIMIT function
SELECT pizza_types.name AS Pizza_Name, CAST(pizzas.price AS DECIMAL(10,2)) AS Price
FROM pizzas
JOIN pizza_types
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY price DESC
LIMIT 1;

-- Alternative (using window function) - without using LIMIT function
WITH cte AS (
SELECT pizza_types.name AS Pizza_Name, CAST(pizzas.price AS DECIMAL(10,2)) AS Price,
RANK() OVER(ORDER BY price DESC) AS rnk
FROM pizzas
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
)
SELECT Pizza_Name, Price FROM cte WHERE rnk = 1;

-- Identify the most common pizza size ordered.
SELECT pizzas.size, COUNT(DISTINCT order_id) AS No_Of_Orders, SUM(quantity) AS Total_Quantity_Ordered
FROM order_details
JOIN pizzas
ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizzas.size
ORDER BY COUNT(DISTINCT order_id) DESC; 

-- List the top 5 most ordered pizza types along with their quantities.
SELECT pizza_types.name AS Pizza, SUM(quantity) AS Total_Ordered
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.name
ORDER BY sum(quantity) DESC
LIMIT 5;

-- Join the necessary tables to find the total quantity of each pizza category ordered
SELECT pizza_types.category AS Pizza, SUM(quantity) AS Total_Quantity_Ordered
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.category
ORDER BY sum(quantity) DESC
LIMIT 5;

-- Determine the distribution of orders by hour of the day (at which time the orders are maximum (for inventory management and resource allocation).
SELECT HOUR(time) AS Hour_Of_The_Day, COUNT(DISTINCT order_id) AS No_Of_Orders
FROM orders
GROUP BY HOUR(time)
ORDER BY No_Of_Orders DESC;

-- Find the category-wise distribution of pizzas (to understand customer behaviour).
SELECT category, COUNT(DISTINCT pizza_type_id) AS No_Of_Pizzas
FROM pizza_types
GROUP BY category
ORDER BY No_Of_Pizzas;


-- Group the orders by date and calculate the average number of pizzas ordered per day.
with cte as(
select orders.date as Date, sum(order_details.quantity) as Total_Pizza_Ordered_that_day
from order_details
join orders on order_details.order_id = orders.order_id
group by orders.date
)
select avg(Total_Pizza_Ordered_that_day) as Avg_Number_of_pizzas_ordered_per_day  from cte;


-- alternate using subquery
select avg(Total_Pizza_Ordered_that_day) as Avg_Number_of_pizzas_ordered_per_day from 
(
	select orders.date as Date, sum(order_details.quantity) as Total_Pizza_Ordered_that_day
	from order_details
	join orders on order_details.order_id = orders.order_id
	group by orders.date
) as pizzas_ordered;


-- Determine the top 3 most ordered pizza types based on revenue.

select pizza_types.name, sum(order_details.quantity*pizzas.price) as Revenue_from_pizza
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.name
order by Revenue_from_pizza desc
LIMIT 3;

-- try doing it using window functions also
WITH cte AS (
select pizza_types.name, sum(order_details.quantity*pizzas.price) as Revenue_from_pizza
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.name
order by Revenue_from_pizza desc
LIMIT 3
)
SELECT Revenue_from_pizza AS Revenue;

WITH pizza_revenue AS (
    SELECT pizza_types.name, 
           SUM(order_details.quantity * pizzas.price) OVER (PARTITION BY pizza_types.name) AS total_revenue,
           ROW_NUMBER() OVER (ORDER BY SUM(order_details.quantity * pizzas.price) DESC) AS row_num
    FROM order_details 
    JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
    JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
)
SELECT name, total_revenue
FROM pizza_revenue
WHERE row_num <= 3;

-- Advanced Questions
-- Calculate the percentage contribution of each pizza type to total revenue
SELECT pizza_types.category,
CONCAT(CAST((SUM(order_details.quantity*pizzas.price)
/
(SELECT SUM(order_details.quantity*pizzas.price)
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
)) *100 AS DECIMAL(10,2)), '%') AS Revenue_Contribution_From_Pizza
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.category
ORDER BY Revenue_Contribution_From_Pizza DESC;

-- revenue contribution from each pizza by pizza name
SELECT pizza_types.name,
CONCAT(CAST((SUM(order_details.quantity*pizzas.price)
/
(SELECT SUM(order_details.quantity*pizzas.price)
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
)) *100 AS DECIMAL(10,2)), '%') AS Revenue_Contribution_From_Pizza
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.name
ORDER BY Revenue_Contribution_From_Pizza DESC;

-- Analyze the cumulative revenue generated over time.
-- use of aggregate window function (to get the cumulative sum)
WITH cte AS (
SELECT date AS Date, CAST(SUM(quantity*price) AS DECIMAL(10,2)) AS Revenue
FROM order_details
JOIN orders ON order_details.order_id = orders.order_id
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
GROUP BY date
)
SELECT Date, Revenue, SUM(Revenue) OVER (ORDER BY date) AS Cumulative_Sum
FROM cte
GROUP BY date, Revenue;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category
WITH cte AS (
SELECT category, name, CAST(SUM(quantity*price) AS DECIMAL(10,2)) AS Revenue
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY category, name
)
, cte1 AS (
SELECT category, name, Revenue,
RANK() OVER (PARTITION BY category ORDER BY Revenue DESC) AS rnk
FROM cte
)
SELECT category, name, Revenue
FROM cte1
WHERE rnk IN (1,2,3)
ORDER BY category, name, Revenue;










