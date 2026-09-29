-- Plain delimited input; fields must not contain embedded delimiters.
%default PRODUCTS '/lab/input/catalog/products.csv'
%default REVIEWS '/lab/input/catalog/reviews.csv'
%default CATEGORY 'Electronics'
%default THRESHOLD '3.0'
%default OUTPUT '/lab/output/flagged-products'
SET default_parallel 1;

catalog_raw = LOAD '$PRODUCTS' USING PigStorage(';')
  AS (product_id:chararray, product_name:chararray, category:chararray, price:double);
reviews_raw = LOAD '$REVIEWS' USING PigStorage(',')
  AS (review_id:chararray, product_id:chararray, rating:double);

catalog_trimmed = FOREACH catalog_raw GENERATE
  TRIM(product_id) AS product_id, TRIM(product_name) AS product_name,
  TRIM(category) AS category, price;
catalog_valid = FILTER catalog_trimmed BY product_id IS NOT NULL
  AND product_id != '' AND product_id != 'product_id'
  AND product_name IS NOT NULL AND product_name != ''
  AND category IS NOT NULL AND price IS NOT NULL AND price >= 0;
catalog = DISTINCT catalog_valid;
selected = FILTER catalog BY category == '$CATEGORY';

reviews_trimmed = FOREACH reviews_raw GENERATE TRIM(review_id) AS review_id,
  TRIM(product_id) AS product_id, rating;
reviews_valid = FILTER reviews_trimmed BY product_id IS NOT NULL
  AND product_id != '' AND review_id IS NOT NULL AND review_id != ''
  AND rating IS NOT NULL AND rating >= 1 AND rating <= 5;
reviews = DISTINCT reviews_valid;

-- Keep products without valid reviews. Filtering the right side AFTER this
-- join would accidentally remove the null rows produced by the left join.
joined = JOIN selected BY product_id LEFT OUTER, reviews BY product_id;
flat = FOREACH joined GENERATE selected::product_id AS product_id,
  selected::product_name AS product_name, selected::category AS category,
  selected::price AS price, reviews::rating AS rating;
grouped = GROUP flat BY product_id;
summary = FOREACH grouped GENERATE group AS product_id,
  MAX(flat.product_name) AS product_name, MAX(flat.category) AS category,
  MAX(flat.price) AS price, AVG(flat.rating) AS average_rating,
  COUNT(flat.rating) AS review_count;
flagged = FILTER summary BY average_rating IS NULL OR average_rating < $THRESHOLD;
ordered = ORDER flagged BY product_id;
STORE ordered INTO '$OUTPUT' USING PigStorage('\t');
