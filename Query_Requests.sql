-- Ad-hoc Request #1 --

SELECT DISTINCT market FROM dim_customer
	WHERE customer LIKE "%Atliq exclusive%" 
AND region LIKE "%APAC%";

-- Ad-hoc Request #2 --

WITH cte1 AS (SELECT 
COUNT(DISTINCT product_code) AS unique_products_2021 FROM gdb0041.dim_product p
	JOIN gdb0041.fact_sales_monthly s
USING (product_code)
	WHERE fiscal_year = 2021
),
    
cte2 AS (SELECT 
COUNT(DISTINCT product_code) AS unique_products_2020 FROM gdb0041.dim_product p
	JOIN gdb0041.fact_sales_monthly s
USING (product_code)
	WHERE fiscal_year = 2020
)

SELECT unique_products_2021, unique_products_2020, 
	ROUND((unique_products_2021 - unique_products_2020)/(unique_products_2020)*100,2) AS percentage_chg
 FROM cte1 CROSS JOIN cte2;

-- Ad-hoc Request #3 --

SELECT segment, COUNT(DISTINCT product_code) AS product_count
	FROM gdb0041.dim_product
GROUP BY segment ORDER BY product_count DESC;

-- Ad-hoc Request #4 --

WITH cte1 AS (SELECT 
segment, COUNT(DISTINCT product_code) AS product_count_2020
	FROM gdb0041.dim_product p
JOIN gdb0041.fact_sales_monthly s
	USING (product_code) WHERE fiscal_year = 2020
GROUP BY segment
),

cte2 AS (SELECT 
segment, COUNT(DISTINCT product_code) AS product_count_2021
	FROM gdb0041.dim_product p
JOIN gdb0041.fact_sales_monthly s
	USING (product_code) WHERE fiscal_year = 2021
GROUP BY segment
)

SELECT segment, product_count_2020, product_count_2021,
	(product_count_2021 - product_count_2020) AS difference 
FROM cte1 JOIN cte2 USING (segment)
	GROUP BY segment ORDER BY difference DESC;

-- Ad-hoc Request #5 --

SELECT 
product_code, product, manufacturing_cost 
	FROM gdb0041.fact_manufacturing_cost m
JOIN gdb0041.dim_product p
	USING (product_code)
WHERE manufacturing_cost IN ((SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost), 
	(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost))
ORDER BY manufacturing_cost DESC;

-- Ad-hoc Request #6 --

SELECT customer_code, customer, ROUND(AVG(pre_invoice_discount_pct)*100,2) AS average_discount_percentage 
	FROM gdb0041.fact_pre_invoice_deductions p
JOIN dim_customer c USING (customer_code)
    WHERE fiscal_year = 2021 AND market LIKE "%india%"
GROUP BY customer_code 
	ORDER BY average_discount_percentage DESC LIMIT 5;

-- Ad-hoc Request #7 --

SELECT MONTHNAME(s.date) AS month, s.fiscal_year, 
	ROUND(SUM(gross_price * sold_quantity),2) AS Gross_sales_amount 
FROM gdb0041.fact_sales_monthly s
	JOIN gdb0041.fact_gross_price g
ON  s.product_code = g.product_code
	JOIN gdb0041.dim_customer c
ON s.customer_code = c.customer_code
	WHERE c.customer LIKE "%atliq exclusive%"
GROUP BY month , s.fiscal_year
	ORDER BY s.fiscal_year

-- Ad-hoc Request #8 --

WITH cte1 AS(SELECT CASE
	WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
    WHEN MONTH(date) IN (12,01,02) THEN 'Q2'
    WHEN MONTH(date) IN (03,04,05) THEN 'Q3'
    ELSE 'Q4'
  END AS quarter, SUM(sold_quantity) AS total_sold_qty
	FROM gdb0041.fact_sales_monthly s
WHERE s.fiscal_year = 2020 GROUP BY quarter
)
SELECT * FROM cte1 GROUP BY total_sold_qty ORDER BY total_sold_qty DESC;

-- Ad-hoc Request #9 --

WITH cte1 AS(SELECT channel, ROUND(SUM(sold_quantity * gross_price)/1000000,2) AS gross_sales_mln
	FROM gdb0041.fact_sales_monthly s
JOIN gdb0041.fact_gross_price g
	ON s.product_code = g.product_code
JOIN gdb0041.dim_customer c
	ON s.customer_code = c.customer_code
WHERE s.fiscal_year = 2021
	GROUP BY channel ORDER BY gross_sales_mln DESC
)

SELECT *, (gross_sales_mln/SUM(gross_sales_mln) OVER())*100 AS percentage
	FROM cte1 GROUP BY channel;

-- Ad-hoc Request #10 --

WITH cte1 AS(SELECT division, product_code, product, SUM(sold_quantity) as total_sold_quantity
	FROM gdb0041.fact_sales_monthly s
JOIN gdb0041.dim_product p
	USING (product_code) WHERE fiscal_year =2021
GROUP BY product, division, product_code
),

cte2 AS(SELECT *, RANK() OVER(partition by division ORDER BY total_sold_quantity DESC) AS drnk
	FROM cte1
)

SELECT * from cte2 WHERE drnk <=3;
