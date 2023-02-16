-- rc=mrc for most current record
WITH modata AS(
  SELECT
    SPLIT(im.company_name,' (')[OFFSET(0)] company_name,
    mo.number mo_number,
    mo.product_code mo_product_code,
    mo.product_category,
    mo.quantity mo_qty,
    CASE WHEN mo.state IN('done','cancel') THEN 0 
         WHEN m.state = 'done' AND move_type = 'output' AND mo.product_code = m.product_code THEN mo.quantity - SUM(m.quantity) OVER k 
         WHEN m.state = 'draft' AND move_type = 'output' THEN mo.quantity 
         ELSE -99999 -- to quickly stop problem 
    END as openQty,
    DATE(DATETIME(mo.create_date,'EST')) mo_create_date,
    mo.effective_date,
    mo.state mo_state,
    CASE WHEN mo.priority = '0' THEN 'Highest'
         WHEN mo.priority = '1' THEN 'High'
         WHEN mo.priority = '2' THEN 'Normal'
         WHEN mo.priority = '3' THEN 'Low'
         WHEN mo.priority = '4' THEN 'Lowest'
         ELSE CONCAT('ERR:[CTE=modata.mo][CASE=OOB][{',mo.priority,'}undefined]')
    END AS mo_priority,
    mo.warehouse_name,
    mo.work_center_name,
    m.product_code,
    m.move_type,
    m.quantity move_quantity,
    m.state move_state,
    im.effective_date im_effective_date,
    m.uom_name,
    m.id,  
    ROW_NUMBER() OVER c AS rc
  FROM `REDACTED_PROJECT.REDACTED_HOST.manufacturing_orders` mo
  LEFT JOIN UNNEST(moves) m  
  INNER JOIN `REDACTED_PROJECT.REDACTED_HOST.inventory_moves` im ON im.id = m.id
  WHERE mo.product_code = m.product_code
  WINDOW 
  w1 AS (PARTITION BY mo.number,mo.product_code,mo.state ORDER BY m.id ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
  w2 AS (PARTITION BY mo.number,mo.product_code ORDER BY m.id ASC), 
  k AS (w1), 
  c AS (w2)
)
SELECT *,MAX(rc) OVER (PARTITION BY mo_number,mo_product_code) mrc FROM modata
