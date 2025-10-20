-- test query to check if database got loaded
SELECT * FROM customers LIMIT 5;

-- advanced query to check schema
SELECT table_schema, table_name FROM information_schema.tables WHERE table_type='BASE TABLE' ORDER BY table_schema, table_name;

-- Create a very simplified new table (for demonstration)  
CREATE TABLE demo_sales (
    demo_id        SERIAL PRIMARY KEY,
    product_id     INTEGER      NOT NULL,
    sale_date      DATE         NOT NULL,
    quantity       INTEGER      NOT NULL,
    unit_price     NUMERIC(10,2) NOT NULL,
    region         TEXT
);

-- Insert some sample records  
INSERT INTO demo_sales (product_id, sale_date, quantity, unit_price, region) VALUES
    (1, '2025-10-01', 5,  20.00, 'North'),
    (2, '2025-10-02', 3,  15.00, 'South'),
    (1, '2025-10-03', 2,  20.00, 'East'),
    (3, '2025-10-04', 10, 12.50, NULL);

-- test the above
select * from demo_sales;

-- Update some records: e.g., fill missing region, adjust price  
UPDATE demo_sales
   SET region = 'Unknown'
 WHERE region IS NULL;

select * from demo_sales
where region = 'Unknown';




-- select *
select  *
from customers;


-- LIMIT
select  *
from customers
limit 10;


-- Basic SELECT with FROM + WHERE + ORDER BY  
SELECT product_id, sale_date, quantity, unit_price, region
  FROM demo_sales
 WHERE quantity >= 3
 ORDER BY sale_date DESC;

-- SELECT with aggregate + GROUP BY  
SELECT region,
       COUNT(*)     AS num_sales,
       SUM(quantity) AS total_qty,
       MAX(quantity) as max_qty,
       AVG(unit_price) AS avg_price
  FROM demo_sales
 GROUP BY region
 ORDER BY total_qty DESC;

-- SELECT with GROUP BY + HAVING + LIMIT  
SELECT region,
       SUM(quantity) AS total_qty
  FROM demo_sales
 GROUP BY region
 HAVING SUM(quantity) > 5
 ORDER BY total_qty DESC
 LIMIT 3;


-- INNER JOIN: only matching rows  
SELECT o.order_id,
       o.order_date,
       c.customer_id,
       c.company_name,
       od.product_id,
       p.product_name,
       od.quantity
  FROM orders AS o
  INNER JOIN customers AS c  ON o.customer_id = c.customer_id
  INNER JOIN order_details AS od ON od.order_id = o.order_id
  INNER JOIN products AS p   ON od.product_id = p.product_id
 WHERE o.order_date >= '1997-01-01'
 ORDER BY o.order_date;

-- LEFT JOIN: all from left side, even if no match on right  
SELECT p.product_id,
       p.product_name,
       s.supplier_id,
       s.company_name AS supplier_name
  FROM products AS p
  LEFT JOIN suppliers AS s ON p.supplier_id = s.supplier_id
 ORDER BY p.product_name;

-- RIGHT JOIN: all from right side, even if no match on left (less common)  
SELECT s.supplier_id,
       s.company_name AS supplier_name,
       p.product_id,
       p.product_name
  FROM products AS p
  RIGHT JOIN suppliers AS s ON p.supplier_id = s.supplier_id
 ORDER BY s.company_name;

-- OUTER JOIN (if you want all rows from both sides)  
SELECT p.product_id,
       p.product_name,
       s.supplier_id,
       s.company_name AS supplier_name
  FROM products AS p
  FULL OUTER JOIN suppliers AS s ON p.supplier_id = s.supplier_id
 ORDER BY supplier_name NULLS LAST;


-- case when
SELECT 
  product_id,
  product_name,
  unit_price,
  CASE 
    WHEN unit_price >= 100 THEN 'Premium'
    WHEN unit_price >= 50 THEN 'Mid-range'
    ELSE 'Budget'
  END AS price_category
FROM products
ORDER BY unit_price DESC
LIMIT 10;

-- coalesce
SELECT 
  customer_id,
  company_name,
  COALESCE(region, 'Unknown') AS customer_region
FROM customers
ORDER BY customer_id
LIMIT 10;

--union
SELECT 
  customer_id,
  company_name,
  'USA' AS country
FROM customers
WHERE country = 'USA'

UNION

SELECT 
  customer_id,
  company_name,
  'Canada' AS country
FROM customers
WHERE country = 'Canada';

-- except
-- All customers who have placed orders
SELECT DISTINCT o.customer_id
FROM orders o

EXCEPT

-- USA-based customers who have placed orders
SELECT DISTINCT o.customer_id
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.country = 'USA';

-- row number window function
SELECT *
FROM (
  SELECT 
    customer_id,
    order_id,
    order_date,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id 
      ORDER BY order_date
    ) AS row_num
  FROM orders
) AS ranked_orders
WHERE row_num = 1;

-- rank
SELECT 
  employee_id,
  SUM(od.unit_price * od.quantity) AS total_sales,
  RANK() OVER (ORDER BY SUM(od.unit_price * od.quantity) DESC) AS sales_rank
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY employee_id;


-- partition by + over
SELECT 
  o.customer_id,
  o.order_id,
  SUM(od.unit_price * od.quantity) AS order_total,
  SUM(od.unit_price * od.quantity) * 100.0 /
    SUM(SUM(od.unit_price * od.quantity)) OVER (PARTITION BY o.customer_id) AS pct_of_customer_total
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.customer_id, o.order_id
ORDER BY o.customer_id, order_total DESC;

-- CTE 1
WITH customer_sales AS (
  SELECT 
    o.customer_id,
    SUM(od.unit_price * od.quantity) AS total_spent
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  GROUP BY o.customer_id
)

SELECT 
  customer_id,
  total_spent
FROM customer_sales
ORDER BY total_spent DESC
LIMIT 5;

-- recursive CTE
WITH RECURSIVE numbers AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM numbers WHERE n < 10
)

SELECT * FROM numbers;


-- CTE 2
WITH customer_sales AS (
  SELECT 
    o.customer_id,
    SUM(od.unit_price * od.quantity) AS total_spent
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  GROUP BY o.customer_id
)

SELECT 
  customer_id,
  total_spent,
  RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM customer_sales
ORDER BY spending_rank;





