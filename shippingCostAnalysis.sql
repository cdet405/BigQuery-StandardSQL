-- 20230302 BUG: primaryProduct join breaks when <1 SO's in 1 CS because rsc<>rsc in this scenario
-- Shipping Cost Analysis Data
WITH s AS(
  SELECT
   company_id,
   m.order_number,
   number,
   IFNULL(shipment_cost,0) shipment_cost,
   carrier,
   carrier_service,
   tracking_number,
   packages_count,
   s.shipment_region_name,
   shipped_date
  FROM `PROJECT.HOST.shipments` s, UNNEST(moves) m
  WHERE s.state = 'done' 
  AND order_number IS NOT NULL 
  AND warehouse_type != '3pl'
  GROUP BY company_id, order_number, number, shipment_cost, carrier, carrier_service, tracking_number,packages_count, shipment_region_name, shipped_date
), 
-- Sales order data
so AS(
	SELECT  
	 so.id,
	 so.order_id,
     so.order_number,
	 so.order_reference,
	 so.channel_name,
	 so.order_date,
	 so.state,
	 l.product_code,
	 l.description,
	 l.listing_sku,
	 l.product_variant_name,
	 l.product_category,
	 l.quantity,
     l.uom_name,
	 l.unit_price,
	 l.amount,
	 l.warehouse_name,
	 SPLIT(so.company_name,' (')[OFFSET(0)] company_name,
	 'new' as debug
 FROM `PROJECT.HOST.sales_orders` as so, UNNEST(lines) as l 
 WHERE order_date >= '2022-11-01'
 AND so.state NOT IN('draft','cancel','failed','ignored')
 AND l.line_type = 'sale'
), 
-- Total Order Value, Initial total shipping charged
sot AS(
  SELECT 
  order_number,
  SUM(amount) TotalOrderAmt,
  IFNULL(SUM(CASE WHEN product_code = 'Shipping' THEN amount ELSE NULL END),0) shippingCharged,
  FROM so
  GROUP BY order_number
),
-- Finds the primary product of order
-- primary product defined as the most expensive product total per order
spp AS(
  SELECT *,ROW_NUMBER() OVER (PARTITION BY order_number) src FROM(
  SELECT
   order_number,
   product_code,
   product_variant_name,
   amount,
   MAX(amount) OVER (PARTITION BY order_number) maxAmount,
  FROM so
  WHERE product_code != 'Shipping' AND amount > 0
  ) WHERE amount = maxAmount 
),
-- Search for orders where shipping was refunded. 
rs AS(
    SELECT  
     so.order_number,
	 so.order_date,
	 so.state,
	 l.line_type,
	 l.description,
	 l.quantity,
	 l.unit_price,
	 l.amount refundedShipping,
	 l.warehouse_name,
	 SPLIT(so.company_name,' (')[OFFSET(0)] company_name,
	 'refund' as debug
 FROM `PROJECT.HOST.sales_orders` as so, UNNEST(lines) as l 
 WHERE order_date >= '2022-11-01'
 AND so.state NOT IN('draft','cancel','failed','ignored')
 AND l.line_type = 'return' AND l.description = 'Shipping refund'
),
-- factures in shipping refund to total
 rsot AS(
   SELECT 
    order_number,
    TotalOrderAmt,
    shippingCharged ogshippingCharged,
    IFNULL(refundedShipping,0) refundedShipping,
    shippingCharged+IFNULL(refundedShipping,0) shippingCharged
   FROM sot
   LEFT JOIN rs USING (order_number)
 ),
-- Base main report
 stg AS(
SELECT
  CASE WHEN company_id = 1 THEN 'CompanyA'
     WHEN company_id = 2 THEN 'CompanyB'
     WHEN company_id = 3 THEN 'CompanyC'
     WHEN company_id = 4 THEN 'CompanyD'
     WHEN company_id = 5 THEN 'CompanyE'
     WHEN company_id = 6 THEN 'CompanyF'
     ELSE CONCAT('ERR:CASE_OOB_[undefinedCompanyID{',company_id,'}@stg]')
  END AS company_name,
  s.order_number,
  s.number,
  rsot.TotalOrderAmt,
  rsot.shippingCharged,
  s.shipment_cost,
  s.carrier,
  s.carrier_service,
  s.packages_count,
  s.tracking_number,
  s.shipment_region_name,
  s.shipped_date,
  COUNT(number) OVER (PARTITION BY number) csCount,
  COUNT(order_number) OVER (PARTITION BY order_number) soCount,
  ROW_NUMBER() OVER (PARTITION BY order_number) rsc,
  ROUND(rsot.shippingCharged/COUNT(order_number) OVER (PARTITION BY order_number),2) dsoCost,
  ROUND(s.shipment_cost/COUNT(number) OVER (PARTITION BY number),2) dcsCost
FROM s
INNER JOIN rsot USING (order_number)
ORDER BY shipped_date DESC
)
-- adds primary product
SELECT stg.*, 
spp.product_code primaryProduct,
IFNULL(spp.product_variant_name,'CS Zero Dollar Order') primaryProductName, 
spp.amount primaryProductAmount
FROM stg
LEFT JOIN spp ON (spp.order_number = stg.order_number AND spp.src = stg.rsc)
