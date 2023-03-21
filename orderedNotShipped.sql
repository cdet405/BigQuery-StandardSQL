-- completed orders that are not yet shipped out of HQ
WITH s AS(
  SELECT 
    CASE 
      WHEN s.company_id = 1 THEN 'companyName1'
      WHEN s.company_id = 2 THEN 'companyName2'
      WHEN s.company_id = 3 THEN 'companyName3'
      WHEN s.company_id = 4 THEN 'companyName4'
      WHEN s.company_id = 5 THEN 'companyName5'
      WHEN s.company_id = 6 THEN 'companyName6'
      WHEN s.company_id = 8 THEN 'companyName7'
     ELSE CONCAT('ERR::OOB::company_id=',s.company_id)
    END company_name,
    s.number,
    s.state,
    m.order_number,
    m.product_code,
    m.quantity,
    m.unit_price,
    m.quantity * m.unit_price amt,
  FROM `project.dataset.shipments` s, UNNEST(moves) m
  WHERE m.order_number IS NOT NULL
   AND s.state NOT IN('done','draft','cancel')
   AND warehouse_type != '3pl'
),
sla AS(
  SELECT 
  number,
  STRING_AGG(product_code,',') allLines,
  STRING_AGG(DISTINCT order_number,',') allOrders,
  SUM(amt) csAmt
  FROM s
  GROUP BY number
)

SELECT 
  s.*, 
  sla.allLines, 
  sla.allOrders, 
  sla.csAmt, 
  ROW_NUMBER() OVER (PARTITION BY number) k 
FROM s
JOIN sla USING (number)
