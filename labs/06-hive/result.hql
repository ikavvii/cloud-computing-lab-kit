USE cloud_lab;
SELECT sale_id, amount,
  CAST(amount * CAST(0.9 AS DECIMAL(2,1)) AS DECIMAL(12,2)) AS discounted_amount,
  YEAR(sale_ts) AS sale_year, MONTH(sale_ts) AS sale_month
FROM sales;
