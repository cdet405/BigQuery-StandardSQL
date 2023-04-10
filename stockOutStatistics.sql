-- *********************************************************
-- Stock Out Date (ONLY HQ WAREHOUSES)
-- Need to figure out hot to get qtyBuildable into this
-- ^ will require fix to snapshot query + fix existing records
-- Need to decide how to treat component list prices
-- once product (ap) becomes base, inner joins need to be left.
-- NULLs in list look to be components or no sales hist. 
--  >could maybe grab from inventorymoves/product but idk on how kosher those values are.
-- Investigate: If BOTF does not have (built/finished) inventory but was buildable (components AV) sku may not exist in inventoryCurrent?
-- which would be an issue, those records would need appened at the specific date, which would also be rough. 
-- **********************************************************
-- fetch inventory data from snapshot log
WITH snap AS(
  SELECT
    company_name,
    dateRecorded,
    product,
    warehouseName,
    qtyOH,
    qtyAvail
  FROM `project.dataset.dailyProductSnap`
  WHERE warehouseName LIKE '%HQ%'
   AND dateRecorded >= '2023-01-01'
   AND qtyOH + qtyAvail > 0
),
-- group records
gr AS(
  SELECT
    dateRecorded,
    product,
    SUM(qtyOH) OH,
    SUM(qtyAvail) AV,
  FROM snap 
  GROUP BY
    dateRecorded,
    product
),
-- window'd partitions
nxt AS(
  SELECT
    product,
    dateRecorded,
    OH,
    AV,
    LAG(dateRecorded)
      OVER (
        PARTITION BY 
          product
        ORDER BY
          dateRecorded DESC
    ) AS nextDate
  FROM gr
),
-- add datediffs
dd AS(
  SELECT 
    *, 
    DATE_DIFF(nextDate,dateRecorded,DAY) days 
  FROM nxt
  ORDER BY
   product, 
   dateRecorded ASC
),
-- resolve company name
dcp AS(
  SELECT
   DISTINCT
    company_name,
    product,
    daterecorded
  FROM snap
),
-- grab sales history
s AS(
    SELECT
  product_code,
  product_variant_name,
  CASE WHEN company_id = 1 THEN 'companyName1'
     WHEN company_id = 2 THEN 'companyName2'
     WHEN company_id = 3 THEN 'companyName3'
     WHEN company_id = 4 THEN 'companyName4'
     WHEN company_id = 5 THEN 'companyName5'
     WHEN company_id = 6 THEN 'companyName6'
     ELSE 'ERR:CASE_OOB_[s]'
  END AS company_name,
  channel_name,
  unit_price,
  quantity,
  order_date
  FROM `project.dataset.sales_orders` s, UNNEST(lines) l
  WHERE order_date >= '2023-01-01'
   AND l.line_type = 'sale' 
    AND s.state IN(
		'processing', 
		'done'
	)
  -- AND channel_name LIKE '%Shopify%'
),
-- max unit price by product from sales
sl AS(
  SELECT
    product_code,
    MAX(unit_price) list
  FROM s
  GROUP BY
   product_code
),
-- Sum Sales + Generate daynum
ss AS(
  SELECT 
  product_code,
  SUM(quantity) tot,
  EXTRACT(DAYOFYEAR FROM order_date) dn
  FROM s 
  WHERE product_code != 'Shipping'
  GROUP BY product_code, dn 
),
-- Fetch Exploded BOM Data & make it math
xb AS(
  SELECT 
  product_code,
  input,
  quantity,
  tot,
  tot * dataset.convert_uom(
	  quantity,
	  UoM,
	  d_uom
  ) itot, --quantity itot --
  dn
  FROM ss
  LEFT JOIN(
    SELECT
      boom.*,
      iu.d_uom,
      iu.p_uom,
      iu.s_uom,
      iu.w_uom
    FROM `project.dataset.explodedBOM` boom
    LEFT JOIN(
      SELECT 
        code, 
        default_uom_name d_uom, 
        purchase_uom_name p_uom, 
        sale_uom_name s_uom,
        weight_uom_name w_uom  
      FROM `project.dataset.products` 
      WHERE active = true 
      ) iu ON iu.code = boom.input
    --WHERE (topSkuBotF = true AND BotF = true) -- << Both top and level BotF for forecast | Commented out for full velocity
     --AND (sequence IS NULL OR sequence = 10)
    WHERE (sequence IS NULL OR sequence = 10) -- only respects default bom
  ) xx ON xx.topSku = product_code
GROUP BY 
  product_code, 
  input, 
  quantity, 
  UoM, 
  d_uom, 
  p_uom, 
  s_uom,
  tot, 
  itot, 
  dn
),
-- Mash it up together
u AS(
  SELECT 
    input product_code, 
    itot tot, 
    dn
   -- ,'xb' dataSource -- used for debugging
  FROM xb 
  UNION ALL 
  SELECT 
    product_code, 
    tot, 
    dn
   -- ,'s' dataSource  -- used for debugging
  FROM ss
),
-- all products
ap AS(
  SELECT 
    code, 
    variant_name, 
    active 
  FROM `project.dataset.products` 
),
-- sale history final
shf AS(
  SELECT  
   product_code,
   SUM(tot) qty,
   dn
  FROM u 
  LEFT JOIN ap ON code = product_code
  WHERE product_code IS NOT NULL
  AND active = true 
  GROUP BY 
    product_code, 
    dn 
  HAVING qty > 0
)
-- final output
SELECT 
  dd.product,
  dd.dateRecorded,
  ROUND(
    SAFE_DIVIDE(
      (
        SELECT 
          SUM(qty) 
        FROM shf 
        WHERE 
          shf.product_code = dd.product 
           AND(
             dn <= EXTRACT(
              DAYOFYEAR 
              FROM 
              dd.dateRecorded
              ) 
             AND 
                dn >= EXTRACT(
                  DAYOFYEAR 
                  FROM 
                  dd.dateRecorded
                )
             -14
            )
        ),
     14
    )
   ,2
  ) AS prev14DA,
  dd.OH,
  dd.AV,
  dd.nextDate,
  dd.days,
  ROUND(
    SAFE_DIVIDE(
      dd.days, 
      14
    )
  ,2
  ) LRratio,
  sl.list,
  gr.OH nextOH,
  gr.AV nextAV,
  dcp.company_name
FROM dd
LEFT JOIN sl ON sl.product_code = dd.product
INNER JOIN gr 
  ON(
    dd.product = gr.product AND dd.nextDate = gr.dateRecorded
  )
INNER JOIN dcp 
  ON(
    dd.product = dcp.product AND dd.dateRecorded = dcp.dateRecorded
  )
WHERE 
  dd.days > 1 
   AND 
    dd.dateRecorded >= '2023-01-14' -- because join based on dayofyear counter 
ORDER BY
  product, 
  dateRecorded ASC
