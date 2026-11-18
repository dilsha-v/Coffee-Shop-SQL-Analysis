------------------------MONDAY COFFEE DATA ANALYSIS  ------------------------------------


CREATE TABLE cities (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    population BIGINT,
    estimated_rent DECIMAL(10,2),
    city_rank INT
);
====================================================================================================
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    city_id INT NOT NULL,

    CONSTRAINT fk_customer_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
);
====================================================================================================
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    price INT NOT NULL
);
====================================================================================================
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE NOT NULL,
    product_id INT NOT NULL,
    customer_id INT NOT NULL,
    total INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),

    CONSTRAINT fk_sales_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT fk_sales_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);
==============================================1======================================================
                                ---Coffee Consumers Count---
select
  city_name,--(1)--
  ROUND((population * 0.25)/1000000,2) AS estimated_coffee_consumers_in_millions,--(2)--
  city_rank--(3)--
from cities
order by 2 desc;  
==============================================2======================================================
                            ---Total Revenue from Coffee Sales----
SELECT
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM sales as s
join customers as c 
  on s.customer_id=c.customer_id
join cities as ci 
  on ci.city_id =c.city_id
WHERE sale_date BETWEEN '2023-10-01' AND '2023-12-31'
group by 1
order by 2 desc;
==============================================3======================================================
                              ---Sales Count for Each Product--- 
SELECT
    p.product_name,
    COUNT(*) AS units_sold
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
GROUP BY p.product_name  
ORDER BY units_sold DESC; 
==============================================4======================================================
                       ---Average Sales Amount per Customer in Each City---
SELECT
    ci.city_name,
    ROUND(sum(s.total)) AS total_revenue,
	count(distinct s.customer_id) as total_customers,
	sum(s.total)/count(distinct s.customer_id::numeric) as average_sales_per_customers
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN cities ci
    ON c.city_id = ci.city_id
GROUP BY 1
ORDER BY 2 DESC;
					
==============================================5======================================================
                      ---City Population and Coffee Consumers---
select
  ci.city_name,
  round(((ci.population * 0.25)/1000000)::numeric,2) as coffee_consumers,
  count(distinct c. customer_id) as unique_customers  
from cities ci 
join customers c
   on ci.city_id = c.city_id
join sales s
   on s.customer_id = c.customer_id
group by ci.city_name,ci.population;   
  
==============================================6======================================================
                            ---Top 3 Selling Products by City --
SELECT *
FROM
(       SELECT
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_sales,
        RANK() OVER(
            PARTITION BY ci.city_name
            ORDER BY COUNT(s.sale_id) DESC
        ) AS rank
    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN cities ci
        ON c.city_id = ci.city_id
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY
        ci.city_name,
        p.product_name
) AS ranked_products
WHERE rank <= 3
ORDER BY city_name, rank;
==============================================7======================================================
                           ---Costumer Segmentation by City---
SELECT
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_customers
FROM customers c
JOIN cities ci
    ON c.city_id = ci.city_id
JOIN sales s
    ON c.customer_id = s.customer_id
GROUP BY ci.city_name
ORDER BY unique_customers DESC;						   
==============================================8======================================================
                            ---Impact of Estimated Rent on Sales---
SELECT
    ci.city_name,
    ROUND(AVG(s.total)::NUMERIC,2) AS avg_sale_per_customer,
    ROUND((ci.estimated_rent / COUNT(DISTINCT c.customer_id))::NUMERIC,2) AS avg_rent_per_customer
FROM cities ci
JOIN customers c
    ON ci.city_id = c.city_id
JOIN sales s
    ON c.customer_id = s.customer_id
GROUP BY ci.city_name, ci.estimated_rent
ORDER BY avg_sale_per_customer DESC;
==============================================9======================================================
                                  ---Monthly Sales Growth---

WITH monthly_sales AS
(SELECT ci.city_name,
        EXTRACT(YEAR FROM s.sale_date)  AS sale_year,
        EXTRACT(MONTH FROM s.sale_date) AS sale_month,
        SUM(s.total) AS total_sale
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN cities ci ON c.city_id = ci.city_id
    GROUP BY ci.city_name, sale_year, sale_month),
growth AS (SELECT city_name, sale_year, sale_month, total_sale,
            LAG(total_sale) OVER (PARTITION BY city_name
            ORDER BY sale_year, sale_month) AS prev_month_sale
            FROM monthly_sales)
SELECT city_name, sale_year, sale_month, total_sale, prev_month_sale,
ROUND((total_sale - prev_month_sale)::numeric/ NULLIF(prev_month_sale, 0) * 100, 2) AS growth_pct
FROM growth
ORDER BY city_name, sale_year, sale_month;								  
==============================================10======================================================
                               --- Market Potential Analysis ---
WITH city_metrics AS
        (SELECT ci.city_name,
        SUM(s.total) AS total_sale,
        ci.estimated_rent AS total_rent,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND((ci.population * 0.25)/1000000.0,2) || 'M' AS estimated_coffee_consumers
        FROM sales s
   JOIN customers c ON s.customer_id = c.customer_id
   JOIN cities ci ON c.city_id = ci.city_id
        GROUP BY ci.city_name, ci.estimated_rent, ci.population)
SELECT city_name,
    ROUND(total_sale/1000000.0, 2) || 'M' AS total_sale,
    ROUND(total_rent/1000.0, 2) || 'K' AS total_rent,
total_customers, estimated_coffee_consumers
FROM city_metrics
ORDER BY total_sale DESC
LIMIT 3;



