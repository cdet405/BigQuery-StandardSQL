-- qtyBuildable v2.1
-- grab explodedBom data
-- troubleshoot tb#2121
WITH xb AS(
  SELECT
    boom.topBomID,
    boom.topSku,
    boom.topBomName,
    boom.topSkuBotF,
    boom.ouom,
    boom.oqty,
    boom.level,
    boom.bomID,
    boom.output,
    boom.BotF,
    boom.input,
    boom.bom_name,
    boom.quantity,
    boom.UoM,
    boom.quantity_buildable_source,
    IFNULL(boom.sequence,10) sequence
  FROM `REDACTED_PROJECT.REDACTED_HOST.explodedBOM` boom
),
-- fetch product default uom
p AS(
  SELECT
    code,
    variant_name,
    default_uom_name,
    purchase_uom_name,
    active,
  FROM `REDACTED_PROJECT.REDACTED_HOST.products`
),
-- grab local inventory
i AS(
  SELECT
    product_code,
    warehouse,
    warehouse_code,
    quantity_on_hand qtyOH,
    quantity_available qtyAvail
  FROM `REDACTED_PROJECT.REDACTED_HOST.inventory_current`
  WHERE warehouse_code IN('WH','VFS HQ','TMP') -- tmp in there for svryStock
),
-- sum iventory by product
pi AS(
  SELECT
    product_code,
    IFNULL(SUM(qtyOH),0) totQtyOH,
    IFNULL(SUM(qtyAvail),0) totQtyAvail,
    FROM i
    GROUP BY product_code
),
-- filtered to only inputs
ii AS(
  SELECT 
    pi.*
  FROM pi
  WHERE product_code IN(
    SELECT 
     DISTINCT 
      input 
    FROM xb
  ) 
),
-- filtered to only outputs
oi AS(
  SELECT 
    pi.*
  FROM pi
  WHERE product_code IN(
    SELECT 
     DISTINCT 
      output 
    FROM xb
  ) 
),
-- filtered to only topSkus
ti AS(
  SELECT 
    pi.*
  FROM pi
  WHERE product_code IN(
    SELECT 
     DISTINCT 
      topSku 
    FROM xb
  ) 
),
-- stg1 qtyBuildable Calc
bi AS(
  SELECT
   sequence,
   topBomID,
   topSkuBotF,
   topSku,
   level,
   bomID,
   BotF,
   output,
   input,
   quantity qtyRequired,
   UoM,
   REDACTED_HOST.convert_uom(quantity,UoM,default_uom_name) d_qtyRequired,
   quantity_buildable_source,
   p.default_uom_name d_uom,
   ii.totQtyAvail i_totQtyAvail,
   oi.totQtyAvail o_totQtyAvail,
   ti.totQtyAvail t_totQtyAvail,
   SAFE_DIVIDE(ii.totQtyAvail,REDACTED_HOST.convert_uom(quantity,UoM,default_uom_name)) qb,
  FROM xb
  LEFT JOIN p ON p.code = input
  LEFT JOIN ii ON ii.product_code = input
  LEFT JOIN oi ON oi.product_code = output
  LEFT JOIN ti ON ti.product_code = topsku
),
-- actual line level buildable count
qbb as (
  SELECT 
    bi.*, 
    TRUNC(
      (
        CASE WHEN quantity_buildable_source = 'quantity_buildable' THEN (
          SELECT 
            MIN(b2.qb) 
          FROM 
            bi b2 
          WHERE 
            b2.level = bi.level + 1 
            AND b2.topBomID = bi.topBomID 
            AND b2.sequence = bi.sequence
        ) WHEN quantity_buildable_source = 'quantity_available+buildable' THEN (
          (
            SELECT 
              MIN(b2.qb) 
            FROM 
              bi b2 
            WHERE 
              b2.level = bi.level + 1 
              AND b2.topBomID = bi.topBomID 
              AND b2.sequence = bi.sequence
          )+ bi.o_totQtyAvail
        ) WHEN quantity_buildable_source = 'quantity_available' THEN bi.qb ELSE 0 END 
      ), 
      0
    ) as qtyBuildable 
  from 
    bi
),
-- buildable by topBom (maximum able to build)
tqb AS(
  SELECT
    qbb.sequence,
    qbb.topBomID,
    MIN(IFNULL(qtyBuildable,0)) minTop
  FROM qbb
  GROUP BY sequence,topBomID
),
-- buildable by levelOutputs (maximum able to build)
oqb AS(
  SELECT
    qbb.sequence,
    qbb.BomID,
    MIN(IFNULL(qtyBuildable,0)) minOut
  FROM qbb
  GROUP BY sequence,BomID
) 
-- final report
SELECT 
  qbb.*, 
  tqb.minTop,
  oqb.minOut
FROM qbb
LEFT JOIN tqb USING (sequence,topBomID)
LEFT JOIN oqb USING (sequence,bomID)
ORDER BY sequence, topSku, level
