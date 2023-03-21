-- Might need changed completely - if they're expecting it to look more like marketing basket
-- should add date variables (so) for data studio, that way they can decide the startdate for nthOrder Count
-- added @startdate variable in datastudio version
WITH so AS(
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
     DATETIME(TIMESTAMP(confirmation_time), "EST")  ts,
     channel_name,
     shipment_address_zip,
     shipment_region_code,
     currency,
     l.product_code,
     l.product_variant_name,
     l.quantity,
     l.amount amountInCurrency,
     -- Amount Converted to Default Currency (USD)
     l.untaxed_amount_cpny_ccy_cache amount,
     l.warehouse_name,
     customer_id,
     customer_name
  FROM `project.dataset.sales_orders` 
  LEFT JOIN UNNEST(lines) l 
  WHERE l.line_type = 'sale' 
    AND state NOT IN('draft','cancel','failed','ignored')
    AND DATETIME(TIMESTAMP(confirmation_time), "EST") >= '2023-02-14'
    AND l.quantity > 0
    AND channel_name NOT LIKE '%Intercompany Transfer'
    AND customer_name != 'Amazon'
    AND l.product_code != 'Shipping'
),
-- distinct customer
dc AS(
  SELECT 
    DISTINCT
      customer_id,
      customer_name
  FROM so
),
dso AS(
  SELECT 
    DISTINCT
      order_number,
      customer_id,
      ts
  FROM so
),
-- customer first sale (in timeframe)
cfs AS(
  SELECT
    dc.customer_id,
    dc.customer_name,
    so.order_number firstOrder,
    MIN(so.ts) firstDate
  FROM dc
  INNER JOIN so USING (customer_id)
  GROUP BY customer_id, customer_name, firstOrder
),
-- was thinking of trying firstvalue, lastvalue and nthvalue but though of this
ctst AS(
  SELECT
    customer_id,
    order_number,
    ts,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ts ASC) nthOrder
  FROM dso
),
-- count nthOrder mainly for reference
nc AS(
  SELECT
    nthOrder,
    COUNT(nthOrder) n  
  FROM ctst
  GROUP BY nthOrder
  ORDER BY nthOrder ASC
),
-- report
rep AS(
  SELECT
    so.company_name,
    so.channel_name,
    so.customer_id,
    so.customer_name,
    so.ts,
    so.confirmation_date,
    ctst.nthOrder,
    so.order_number,
    so.product_code,
    so.quantity,
    so.amount,
    CASE 
      WHEN 
        EXISTS(
          SELECT 
            x.customer_id 
          FROM ctst x 
          WHERE 
            x.customer_id = so.customer_id 
              AND x.nthOrder > 1 
         ) 
      THEN 'multipleOrders' 
      ELSE 'onlyOrder' 
    END returning
  FROM so
  INNER JOIN ctst USING (order_number,customer_id,ts) 
)
SELECT * FROM rep
--WHERE returning = 'multipleOrders' -- filtered in datastudio
ORDER BY customer_id, nthOrder DESC
