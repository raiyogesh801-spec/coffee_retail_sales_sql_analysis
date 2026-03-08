-- Monday Coffee Data Analysis

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

--------------------------------------------------
-- Q1 Coffee Consumers Count (25% of population)
--------------------------------------------------

SELECT 
    city_name,
    ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions,
    city_rank
FROM city
ORDER BY coffee_consumers_in_millions DESC;

--------------------------------------------------
-- Q2 Total Revenue (Last Quarter of 2023)
--------------------------------------------------

SELECT 
    SUM(total) AS total_revenue
FROM sales
WHERE YEAR(sale_date) = 2023
AND QUARTER(sale_date) = 4;

-- Revenue by City

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
WHERE YEAR(s.sale_date) = 2023
AND QUARTER(s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

--------------------------------------------------
-- Q3 Sales Count for Each Product
--------------------------------------------------

SELECT 
    p.product_name,
    COUNT(s.sale_id) AS total_orders
FROM products p
LEFT JOIN sales s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;

--------------------------------------------------
-- Q4 Average Sales Amount per City
--------------------------------------------------

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(
        SUM(s.total) / COUNT(DISTINCT s.customer_id),
        2
    ) AS avg_sale_per_customer
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

--------------------------------------------------
-- Q5 City Population vs Coffee Consumers
--------------------------------------------------

WITH city_table AS
(
    SELECT 
        city_name,
        ROUND((population * 0.25)/1000000, 2) AS coffee_consumers
    FROM city
),

customers_table AS
(
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_customers
    FROM sales s
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)

SELECT 
    ct.city_name,
    ctt.coffee_consumers AS coffee_consumers_in_millions,
    ct.unique_customers
FROM customers_table ct
JOIN city_table ctt 
ON ct.city_name = ctt.city_name;

--------------------------------------------------
-- Q6 Top 3 Selling Products by City
--------------------------------------------------

SELECT *
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER(
            PARTITION BY ci.city_name 
            ORDER BY COUNT(s.sale_id) DESC
        ) AS ranking
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) ranked_products
WHERE ranking <= 3;

--------------------------------------------------
-- Q7 Unique Coffee Customers by City
--------------------------------------------------

SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_customers
FROM city ci
LEFT JOIN customers c ON c.city_id = ci.city_id
JOIN sales s ON s.customer_id = c.customer_id
GROUP BY ci.city_name;

--------------------------------------------------
-- Q8 Average Sale vs Rent
--------------------------------------------------

WITH city_sales AS
(
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_per_customer
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),

city_rent AS
(
    SELECT 
        city_name,
        estimated_rent
    FROM city
)

SELECT 
    cr.city_name,
    cr.estimated_rent,
    cs.total_customers,
    cs.avg_sale_per_customer,
    ROUND(
        cr.estimated_rent / cs.total_customers,
        2
    ) AS avg_rent_per_customer
FROM city_rent cr
JOIN city_sales cs 
ON cr.city_name = cs.city_name
ORDER BY avg_sale_per_customer DESC;

--------------------------------------------------
-- Q9 Monthly Sales Growth
--------------------------------------------------

WITH monthly_sales AS
(
    SELECT 
        ci.city_name,
        MONTH(s.sale_date) AS month,
        YEAR(s.sale_date) AS year,
        SUM(s.total) AS total_sales
    FROM sales s
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, YEAR(s.sale_date), MONTH(s.sale_date)
),

growth_data AS
(
    SELECT
        city_name,
        month,
        year,
        total_sales AS current_month_sales,
        LAG(total_sales) OVER(
            PARTITION BY city_name 
            ORDER BY year, month
        ) AS last_month_sales
    FROM monthly_sales
)

SELECT
    city_name,
    month,
    year,
    current_month_sales,
    last_month_sales,
    ROUND(
        ((current_month_sales - last_month_sales) / last_month_sales) * 100,
        2
    ) AS growth_percentage
FROM growth_data
WHERE last_month_sales IS NOT NULL;

--------------------------------------------------
-- Q10 Market Potential Analysis
--------------------------------------------------

WITH city_sales AS
(
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_per_customer
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),

city_info AS
(
    SELECT 
        city_name,
        estimated_rent,
        ROUND((population * 0.25)/1000000, 3) 
        AS estimated_coffee_consumers_millions
    FROM city
)

SELECT 
    ci.city_name,
    cs.total_revenue,
    ci.estimated_rent,
    cs.total_customers,
    ci.estimated_coffee_consumers_millions,
    cs.avg_sale_per_customer,
    ROUND(
        ci.estimated_rent / cs.total_customers,
        2
    ) AS avg_rent_per_customer
FROM city_info ci
JOIN city_sales cs 
ON ci.city_name = cs.city_name
ORDER BY total_revenue DESC;

-----------------------------------------
-- Q11 — Top Revenue Generating Products
-----------------------------------------
-- Which products generate the highest revenue overall?
-----------------------------------------
SELECT 
    p.product_name,
    SUM(s.total) AS total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-----------------------------------------
-- Q12 — Revenue Contribution by City
-----------------------------------------
-- What percentage of total revenue comes from each city?
-----------------------------------------
SELECT 
    ci.city_name,
    SUM(s.total) AS city_revenue,
    ROUND(
        SUM(s.total) / (SELECT SUM(total) FROM sales) * 100,
        2
    ) AS revenue_percentage
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY city_revenue DESC;
-----------------------------------------
-- Q13 — Best Performing Product in Each City (Revenue)
-----------------------------------------

SELECT *
FROM
(
SELECT 
    ci.city_name,
    p.product_name,
    SUM(s.total) AS revenue,
    DENSE_RANK() OVER(
        PARTITION BY ci.city_name 
        ORDER BY SUM(s.total) DESC
    ) AS rank_num
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name, p.product_name
) t
WHERE rank_num = 1;
-----------------------------------------
-- Q14 — Monthly Revenue Trend
-----------------------------------------

SELECT 
    YEAR(sale_date) AS year,
    MONTH(sale_date) AS month,
    SUM(total) AS monthly_revenue
FROM sales
GROUP BY year, month
ORDER BY year, month;
-----------------------------------------
-- Q15 — Customer Purchase Frequency:
-- How many orders each customer makes
-----------------------------------------
SELECT 
    customer_id,
    COUNT(sale_id) AS total_orders,
    SUM(total) AS total_spent
FROM sales
GROUP BY customer_id
ORDER BY total_spent DESC;
-----------------------------------------
-- Q16 — High Value Customers
-- Customers spending above average
-----------------------------------------
WITH customer_spending AS
(
SELECT 
    customer_id,
    SUM(total) AS total_spent
FROM sales
GROUP BY customer_id
)

SELECT *
FROM customer_spending
WHERE total_spent >
(
SELECT AVG(total_spent)
FROM customer_spending
);
-----------------------------------------
-- Q17 — Product Revenue Share (Market Share Analysis)
-- Question:What percentage of total revenue does each product contribute?
-----------------------------------------
SELECT 
    p.product_name,
    SUM(s.total) AS product_revenue,
    ROUND(
        SUM(s.total) / (SELECT SUM(total) FROM sales) * 100,
        2
    ) AS revenue_share_percentage
FROM sales s
JOIN products p 
ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY product_revenue DESC;
-----------------------------------------
-- Q18 — Customer Distribution by City
-----------------------------------------
SELECT 
    ci.city_name,
    COUNT(c.customer_id) AS total_customers
FROM city ci
LEFT JOIN customers c
ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_customers DESC;
-----------------------------------------
-- Q19 — Top 5 Customers by Revenue in Each City
-- Question: Who are the top 5 highest-spending customers in each city?
-----------------------------------------
SELECT *
FROM
(
SELECT 
    ci.city_name,
    c.customer_id,
    SUM(s.total) AS total_spent,
    DENSE_RANK() OVER(
        PARTITION BY ci.city_name 
        ORDER BY SUM(s.total) DESC
    ) AS customer_rank
FROM sales s
JOIN customers c 
ON s.customer_id = c.customer_id
JOIN city ci 
ON ci.city_id = c.city_id
GROUP BY ci.city_name, c.customer_id
) ranked_customers
WHERE customer_rank <= 5;
-----------------------------------------
-- Q20 — Customer Lifetime Value (CLV)
-----------------------------------------
SELECT 
    c.customer_id,
    ci.city_name,
    COUNT(s.sale_id) AS total_orders,
    SUM(s.total) AS lifetime_value
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY c.customer_id, ci.city_name
ORDER BY lifetime_value DESC;