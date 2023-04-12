-- orders vs shipments by day
WITH csc AS(
  SELECT  
    company_id,
    shipped_date,
    COUNT(
      DISTINCT 
      m.order_number
    ) distinctOrdersShipped,
    COUNT(
      DISTINCT 
      s.number
    ) distinctShipments
  FROM `project.dataset.shipments` s, UNNEST(moves) m
  WHERE warehouse_type = 'operated'
  GROUP BY 
    company_id, 
    shipped_date
  ORDER BY 
    shipped_date DESC,
    company_id ASC
),
cso AS(
  SELECT 
    company_id, 
    channel_name,
    FORMAT_DATETIME(
      '%F', 
      DATETIME(
        TIMESTAMP(confirmation_time), 
        "EST"
      )
    ) confirmation_date, 
    COUNT(
      DISTINCT 
      order_number
    ) ordersPlaced 
  FROM 
    `project.dataset.sales_orders` 
    ,UNNEST(lines) l 
  WHERE 
    (
      l.line_type = 'sale' 
      AND l.warehouse_name LIKE '%HQ%' 
      AND product_name != 'Shipping'
      AND l.fulfil_strategy = 'ship'
      AND l.quantity > 0
    ) 
    AND state NOT IN(
      'draft', 
      'cancel', 
      'failed', 
      'ignored'
    ) 
    AND order_date >= '2022-11-01' 
    AND channel_name NOT LIKE '%Intercompany Transfer' 
  GROUP BY 
    company_id,
    channel_name,
    confirmation_date 
  ORDER BY 
    confirmation_date DESC, 
    company_id ASC,
    channel_name ASC
) 
SELECT 
  CASE WHEN cso.company_id = 2 THEN 'name1' 
       WHEN cso.company_id = 3 THEN 'name2' 
       WHEN cso.company_id = 4 THEN 'name3' 
       WHEN cso.company_id = 5 THEN 'name4' 
       WHEN cso.company_id = 6 THEN 'name5' 
    ELSE CONCAT(
      'ERR:[company_id{', 
      cso.company_id,
      '}undefined]'
    ) 
  END company_name,
  cso.channel_name,
  cso.confirmation_date date, 
  cso.ordersPlaced, 
  IFNULL(
    csc.distinctOrdersShipped,
     0
    ) distinctOrdersShipped, 
  IFNULL(
    csc.distinctShipments, 
    0
  ) distinctShipments 
FROM 
  cso 
  LEFT JOIN 
    csc 
      ON csc.company_id = cso.company_id 
        AND DATE(csc.shipped_date) = DATE(cso.confirmation_date) 
ORDER BY 
  date DESC, 
  company_name ASC
