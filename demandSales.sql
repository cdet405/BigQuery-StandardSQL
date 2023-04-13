-- data source for looker data studio
-- demandSales
-- rev notes
/* 
1.company_name is apparently user editable, creating duplicate unique company_names
company_id remains unique. added case statement to resolve company_name.
2.a premigration channel_name from unfulfilled orders exists in data. resolved by if statement.
3.CA store launched, updated amount column to use converted to usd values.
*/
SELECT 
  CASE WHEN company_id = 2 THEN 'companyName1'
     WHEN company_id = 3 THEN 'companyName2'
     WHEN company_id = 4 THEN 'companyName3'
     WHEN company_id = 5 THEN 'companyName4'
     WHEN company_id = 6 THEN 'companyName5'
     ELSE CONCAT('ERR:[action=break][type=OOB][note:company_id{',company_id,'}undefined]')
  END AS company_name,
  order_number,
  order_reference,
  order_date,
  FORMAT_DATETIME('%F',DATETIME(TIMESTAMP(confirmation_time), "EST")) confirmation_date,
  FORMAT_DATETIME('%k',DATETIME(TIMESTAMP(confirmation_time), "EST")) confirmation_hour, 
  DATETIME(TIMESTAMP(confirmation_time), "EST")  timestamp,
  IF(channel_name='xxx - xxx Shopify','xxx - Shopify',channel_name) channel_name,
  shipment_address_zip,
  shipment_region_code,
  currency,
  l.product_code,
  l.product_variant_name,
  l.quantity,
  l.amount  amountInCurrency, 
  -- Amount Converted to Default Currency (USD)
  l.untaxed_amount_cpny_ccy_cache amount,
  l.warehouse_name
FROM `project.dataset.sales_orders` 
LEFT JOIN UNNEST(lines) l -- Left Join to preserve line.id NULL values 
WHERE (l.line_type = 'sale' OR l.line_type IS NULL) -- NULL Accounts for pending unsync'd Amaz Lines
 AND state NOT IN('draft','cancel','failed','ignored')
 AND order_date >= '2022-11-01'  -- partition on order_date however report uses confirmation_date
 AND (l.quantity > 0 OR l.quantity IS NULL) -- NULL Accounts for pending unsync'd Amaz Lines
 AND channel_name NOT LIKE '%Intercompany Transfer' -- inventory transfers go through salesOrders
