-- data source for looker data studio
-- demandSales 
SELECT 
  company_name,
  order_number,
  order_reference,
  order_date,
  FORMAT_DATETIME('%F',DATETIME(TIMESTAMP(confirmation_time), "EST")) confirmation_date,
  FORMAT_DATETIME('%k',DATETIME(TIMESTAMP(confirmation_time), "EST")) confirmation_hour, 
  DATETIME(TIMESTAMP(confirmation_time), "EST")  timestamp,
  channel_name,
  shipment_address_zip,
  shipment_region_code,
  currency,
  l.product_code,
  l.product_variant_name,
  l.quantity,
  l.amount  amount, 
  l.warehouse_name
FROM `project.dataset.sales_orders` 
LEFT JOIN UNNEST(lines) l -- Left Join to preserve line.id NULL values 
WHERE (l.line_type = 'sale' OR l.line_type IS NULL) -- NULL Accounts for pending unsync'd Amaz Lines
 AND state NOT IN('draft','cancel','failed','ignored')
 AND order_date >= '2022-11-01'  -- partition on order_date however report uses confirmation_date
 AND (l.quantity > 0 OR l.quantity IS NULL) -- NULL Accounts for pending unsync'd Amaz Lines
 AND channel_name NOT LIKE '%Intercompany Transfer' -- inventory transfers go through salesOrders
