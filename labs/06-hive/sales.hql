-- The given CSV is unquoted, so LazySimpleSerDe supports typed columns.
-- For quoted commas, use OpenCSVSerde STRING staging columns then cast.
CREATE DATABASE IF NOT EXISTS cloud_lab;
USE cloud_lab;
-- EXTERNAL avoids Hive 4 managed-table ACID requirements for raw TEXTFILE.
CREATE EXTERNAL TABLE IF NOT EXISTS sales (
  sale_id BIGINT,
  sale_ts TIMESTAMP,
  amount DECIMAL(12,2),
  product_id STRING,
  region STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
NULL DEFINED AS ''
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

-- LOCAL means the HiveServer2 container's filesystem, not your Windows PC.
LOAD DATA LOCAL INPATH '/workspace/sales_raw.csv' OVERWRITE INTO TABLE sales;

-- c) All records (8 rows; the header is skipped by the reader).
SELECT * FROM sales;

-- d) Preserve unknown amounts: NULL multiplied by 0.9 remains NULL.
SELECT sale_id, amount,
  CAST(amount * CAST(0.9 AS DECIMAL(2,1)) AS DECIMAL(12,2)) AS discounted_amount
FROM sales;

-- e) Year and month from the typed timestamp.
SELECT sale_id, YEAR(sale_ts) AS sale_year, MONTH(sale_ts) AS sale_month FROM sales;

-- f) Complete required result.
SELECT sale_id, amount,
  CAST(amount * CAST(0.9 AS DECIMAL(2,1)) AS DECIMAL(12,2)) AS discounted_amount,
  YEAR(sale_ts) AS sale_year, MONTH(sale_ts) AS sale_month
FROM sales;

-- ONLY if the examiner explicitly says missing amounts count as zero:
-- SELECT sale_id, CAST(COALESCE(amount, CAST(0 AS DECIMAL(12,2)))
--   * CAST(0.9 AS DECIMAL(2,1)) AS DECIMAL(12,2)) AS discounted_amount FROM sales;
