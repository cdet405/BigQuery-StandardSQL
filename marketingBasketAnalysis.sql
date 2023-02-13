-- marketing basket analysis
-- variables only for BigQuery, DataStudio uses @prefixVariables
DECLARE x,y DATE; -- comment out for DS
SET x = '2023-01-01'; -- comment out for DS
SET y = CURRENT_DATE(); -- comment out for DS

WITH sales AS(
  SELECT * from `REDACTED_PROJECT.REDACTED_HOST.sales_orders` , UNNEST(lines)
  WHERE DATE(confirmation_time) BETWEEN x AND y -- comment out for DS
  --WHERE DATE(confirmation_time) BETWEEN PARSE_DATE("%Y%m%d",@DS_START_DATE) AND PARSE_DATE("%Y%m%d",@DS_END_DATE) -- uncomment for DS
  AND product_code NOT IN('Shipping','shipping','SHIPPING','ship','Ship','SHIP') -- Remove All Flavors of Shipping
  AND line_type = 'sale' AND state NOT IN('draft','cancel','failed','ignored') -- Remove any nonvalid orders
),
-- create marketing basket 
basket AS(
SELECT  
    CASE 
     WHEN a.company_id = 1 THEN 'RedactedCompanyNameA'
     WHEN a.company_id = 2 THEN 'RedactedCompanyNameB'
     WHEN a.company_id = 3 THEN 'RedactedCompanyNameC'
     WHEN a.company_id = 4 THEN 'RedactedCompanyNameD'
     WHEN a.company_id = 5 THEN 'RedactedCompanyNameE'
     WHEN a.company_id = 6 THEN 'RedactedCompanyNameF'
     ELSE CONCAT('ERR:CASE_OOB_[basket{id=',company_id,'}]'
   END AS company_name,
   CONCAT(LEAST(a.product_code, b.product_code), ' + ', GREATEST(a.product_code, b.product_code)) skus,  
   CONCAT(LEAST(a.product_variant_name, b.product_variant_name), ' + ', GREATEST(a.product_variant_name, b.product_variant_name)) product_names,
   COUNT(*) / 2 as times_bought_together
FROM sales AS a
INNER JOIN sales AS b
    ON a.order_id = b.order_id
    AND a.product_code != b.product_code
GROUP BY
    company_name, skus, product_names
HAVING times_bought_together >=5
), 
-- total up orders with skus individually
tot AS(
  SELECT 
    product_code,
    COUNT(product_code) cnt
  FROM sales
  GROUP BY product_code
)
-- final report
SELECT 
  basket.*,
  tot.cnt firstSkuTot,
  tot2.cnt secondSkuTot, 
  ROUND(times_bought_together/(tot.cnt+tot2.cnt),3) freq
FROM basket
LEFT JOIN tot ON tot.product_code = SPLIT(basket.skus,' + ')[OFFSET(0)]
LEFT JOIN tot tot2 ON tot2.product_code = SPLIT(basket.skus,' + ')[OFFSET(1)]
ORDER BY times_bought_together desc ,freq desc