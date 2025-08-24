
WITH cte1 AS (
	SELECT DISTINCT
		s.customerkey, 
		CONCAT(TRIM(givenname), ' ', TRIM(surname)) AS cleaned_name,
		MIN(orderdate) OVER(PARTITION BY s.customerkey) AS first_purchase_date,
		MAX(orderdate) OVER(PARTITION BY s.customerkey) AS last_purchase_date,
		CASE 
			WHEN MAX(orderdate) OVER(PARTITION BY s.customerkey) >= (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 MONTH' THEN 'Active'
			ELSE 'Churned'
		END AS customer_status	
	FROM sales s
	LEFT JOIN customer c ON c.customerkey = s.customerkey
)

SELECT 
	c.customerkey,
	c.cleaned_name,
	c.last_purchase_date,
	c.customer_status 
FROM cte1 c
WHERE first_purchase_date < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 MONTH';


WITH purchase_date AS (
	SELECT 
		s.customerkey,
		MIN(orderdate) AS first_purchase_date,
		MAX(orderdate) AS last_purchase_date	
	FROM sales s
	GROUP BY s.customerkey
)
SELECT 
	p.customerkey,
	CONCAT(TRIM(givenname), ' ', TRIM(surname)) AS cleaned_name,
	p.last_purchase_date,
	CASE 
		WHEN last_purchase_date >= (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 MONTH' THEN 'Active'
		ELSE 'Churned'
	END AS customer_status	
FROM purchase_date p
LEFT JOIN customer c ON c.customerkey = p.customerkey
WHERE p.first_purchase_date < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 MONTH';

WITH cte2 AS (
	SELECT 
		customerkey,
		MAX(cleaned_name) AS cleaned_name,
		MAX(orderdate) AS last_purchase_date,
		MAX(cohort_year) AS cohort_year,
		CASE 
			WHEN MAX(orderdate) >= (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 MONTH' THEN 'Active'
			ELSE 'Churned'
		END AS customer_status
	FROM cohort_analysis
	WHERE first_purchase_date < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 MONTH'
	GROUP BY customerkey
)
SELECT 
	cohort_year,
	COUNT(CASE WHEN customer_status = 'Active' THEN  cte2.customerkey END) AS active_customers,
	COUNT(CASE WHEN customer_status = 'Churned' THEN cte2.customerkey END) AS churned_customers,
	COUNT(customerkey) AS total_customers_per_cohort,
	SUM(COUNT(customerkey)) OVER () AS total_customers
FROM cte2 
GROUP BY cohort_year;
	
	


