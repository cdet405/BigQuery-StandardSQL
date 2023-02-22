-- MoM Product Demand Sales 
WITH so AS(
SELECT 
  CASE WHEN company_id = 2 THEN 'CompanyNameA'
       WHEN company_id = 3 THEN 'CompanyNameB'
       WHEN company_id = 4 THEN 'CompanyNameC'
       WHEN company_id = 5 THEN 'CompanyNameD'
       WHEN company_id = 6 THEN 'CompanyNameE. '
       ELSE CONCAT('ERR:[CTE=so][CASE=OOB{id=',company_id,'}]')
  END AS company_name,
  order_number,
  order_reference,
  DATE(TIMESTAMP(confirmation_time, "EST"))  timestamp,
  channel_name,
  l.product_code,
  l.product_variant_name,
  l.quantity,
  l.amount
FROM `REDACTED_PROJECT.REDACTED_HOST.sales_orders` 
LEFT JOIN UNNEST(lines) l
WHERE (l.line_type = 'sale' OR l.line_type IS NULL) -- NULL Brings in Partial Sync 3Porders
AND state NOT IN('draft','cancel','failed','ignored') 
AND order_date >= '2022-11-01' -- go live date of instance
AND (l.quantity > 0 OR l.quantity IS NULL) -- qty > 0 eliminates return/cancel/etc line items, NULL for 3P
AND channel_name NOT LIKE '%Intercompany Transfer' -- Intercompany Inventory Moves occur Via PO/SO 
)
-- pivot data 
SELECT * FROM(
SELECT company_name,channel_name, product_code, quantity, CONCAT('DF',CAST(FORMAT_DATE('%G%m',so.timestamp) AS STRING)) AS DateFrame from so)
-- NOTE: pivot headers cant be dynamically named w/o using EXECUTE IMMEDIATE which isnt an option for this use case. Update When Needed
PIVOT(SUM(quantity) FOR DateFrame IN('DF202211','DF202212','DF202301','DF202302','DF202303','DF202304','DF202305','DF202306','DF202307','DF202308','DF202309','DF202310','DF202311','DF202312'))
;