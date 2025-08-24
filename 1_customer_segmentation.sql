
WITH customer_ltv AS (
	SELECT
		customerkey,
		cleaned_name,
		SUM(total_net_revenue) AS total_ltv
	FROM cohort_analysis
	GROUP BY 
		customerkey, 
		cleaned_name
), percentiles AS (
		SELECT 
			PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_ltv) AS perc_25,
			PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_ltv)	AS perc_75
		FROM customer_ltv
), customer_segment AS (
	SELECT
	customer_ltv.*,
	CASE 
		WHEN total_ltv < perc_25 THEN '1 - Low value'
		WHEN total_ltv >= perc_75 THEN '3 - High value'
		ELSE '2 - Mid value'
	END AS customer_value
FROM 
	customer_ltv, 
	percentiles
ORDER BY customerkey
)
	
SELECT 
	customer_value,
	SUM(total_ltv) AS total_ltv,
	SUM(total_ltv) / (SELECT SUM(total_ltv) FROM customer_segment) AS ltv_percentage,
	COUNT(customerkey) AS customer_count,
	SUM(total_ltv) / COUNT(customerkey) AS average_ltv
FROM customer_segment
GROUP BY customer_value
ORDER BY total_ltv DESC;
