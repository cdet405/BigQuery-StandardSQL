INSERT INTO `project.dataset.dailyProductSnap` (
  company_name,
  product,
  productVariantName,
  warehouseName,
  warehouseCode,
  qtyOH,
  qtyAvail,
  qtyBuildable,
  active
)

with i as( 
       SELECT 
       product_code AS product, 
       product_variant_name AS productVariantName, 
       warehouse AS warehouseName, 
       warehouse_code AS warehouseCode, 
       quantity_on_hand AS qtyOH, 
       quantity_available AS qtyAvail 
       FROM `project.dataset.inventory_current` 
       ), p as( 
         SELECT 
       code AS product, 
       active 
       FROM `project.dataset.products` 
       ), pc AS( 
       SELECT o.product_code parent, i.product_code child, i.quantity 
       FROM `project.dataset.production_boms` ,unnest(outputs) o , unnest(inputs) i 
       WHERE active = true) 
       , pcnt as( 
         SELECT 
         parent, 
         count(parent) parentCount 
         FROM pc 
         GROUP BY parent) 
       , children AS( 
       SELECT DISTINCT child FROM pc 
       ), cs AS( 
       SELECT 
       product_code, 
       quantity_on_hand onHand, 
       quantity_available 
       FROM `project.dataset.inventory_current` 
       WHERE product_code IN(SELECT child FROM children)) 
       , ps AS( 
         SELECT 
       product_code, 
       quantity_on_hand, 
       quantity_available 
       FROM `project.dataset.inventory_current` 
       WHERE product_code IN(SELECT parent FROM pcnt) AND warehouse_code = 'WH') 
       ,ccm as(SELECT 
       pc.*, 
       cs.quantity_available, 
       IF(cs.quantity_available >= pc.quantity,1,0) canMake, 
       SAFE_DIVIDE(cs.quantity_available,pc.quantity) qtyBuildable 
       FROM pc 
       LEFT JOIN cs ON cs.product_code = pc.child 
       ), mb as( 
       SELECT parent, min(IFNULL(qtyBuildable,0)) qtyBuildable 
       FROM ccm GROUP BY parent), 
       psl as( 
       SELECT 
       parent, 
       SUM(canMake) allChildrenInStock, 
       parentCount, 
       IF(SUM(canMake)>=parentCount,1,0) instock, 
       TRUNC(mb.qtyBuildable,0) as qtyBuildable, 
       IFNULL(ps.quantity_on_hand,0) parentOnHand 
       FROM mb 
       LEFT JOIN pcnt using (parent) 
       LEFT JOIN ccm using (parent) 
       LEFT JOIN ps ON ps.product_code = parent 
       GROUP BY parent, parentCount, qtyBuildable, parentOnHand 
       ),c as(
        SELECT product_code, company_name,
        row_number() OVER (partition by product_code order by cp desc) crk
        FROM(
           SELECT  product_code,
           CASE WHEN company_id = 1 THEN 'companyName'
             WHEN company_id = 2 THEN 'companyName'
             WHEN company_id = 3 THEN 'companyName'
             WHEN company_id = 4 THEN 'companyName'
             WHEN company_id = 5 THEN 'companyName'
             WHEN company_id = 6 THEN 'companyName'
             ELSE CONCAT('ERR:CASE_OOB_[company_id=',company_id,']')
           END AS company_name, 
           COUNT(product_code) cp  
           FROM `project.dataset.inventory_moves`
           GROUP BY product_code, company_name
          )
      )
       ,insrt as( 
       SELECT 
       company_name,
       product, 
       productVariantName, 
       warehouseName, 
       warehouseCode, 
       qtyOH, 
       qtyAvail, 
       psl.qtyBuildable, 
       active
       FROM i 
       LEFT JOIN p using (product) 
       LEFT JOIN psl on psl.parent = i.product 
       INNER JOIN c ON c.product_code = i.product AND crk = 1
       ) 
       SELECT * FROM insrt;