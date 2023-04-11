-- * do not use * qi fail cd * 
-- concecpt for orders completed on a given day
--------------------------------------------------------------------------------
-- not moving forward with this because of an issue
-- issue being write_date only yeilds accurate done status 
-- if the order being moved to done is the final step in the orders lifecycle
-- if any modification is made to the order post shipment such as
-- return, updated note etc, the logic is no longer accurate. 
--------------------------------------------------------------------------------

-- fetch count of orders in done status on given day
SELECT 
  DATE(s.write_date) dt,
  COUNT(DISTINCT order_number) x
FROM `project.dataset.sales_orders` s
, UNNEST(lines) l
WHERE s.state = 'done'
 AND (
   l.warehouse_name LIKE '%HQ%' 
    AND l.product_name != 'Shipping' 
    AND l.fulfil_strategy = 'ship' 
    AND l.line_type = 'sale'
  )
GROUP BY dt
ORDER BY dt DESC
--------------------------------------------------------------------------------
-- for exploding the results (trouble shooting)
--------------------------------------------------------------------------------
SELECT 
  DATE(s.write_date) dt,
  order_number,
  product_code,
  l.product_name,
  l.line_type
FROM `project.dataset.sales_orders` s
, UNNEST(lines) l
WHERE DATE(write_date) = '2023-03-25'
AND s.state='done'
AND (
   l.warehouse_name LIKE '%HQ%' 
    AND l.product_name != 'Shipping' 
    AND l.fulfil_strategy = 'ship' 
    AND l.line_type = 'sale'
  )
  --------------------------------------------------------------------------------
-- further trouble shooting, deep dive on raw tables - orders
--------------------------------------------------------------------------------
SELECT * FROM `project.dataset.sales_orders` WHERE DATE(write_date) = '2023-03-25' 
AND(
  order_number='SO324505'
   OR
  order_number='SO346056'
)
--------------------------------------------------------------------------------
-- ditto - shipments
--------------------------------------------------------------------------------
SELECT * FROM `project.dataset.shipments`
WHERE number='CS129974'
