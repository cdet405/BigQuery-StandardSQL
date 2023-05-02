WITH p AS(
  SELECT 
    code,
    purchase_uom_name p_uom,
    default_uom_name d_uom,
    sale_uom_name s_uom,
    active,
    c.cost,
    c.costing_method method,
    c.company_name,
    c.currency_code
  FROM `project.dataset.products`
  ,UNNEST(costs) c 
)
SELECT 
  * 
FROM(
  SELECT 
    code, 
    active,
    p_uom,
    d_uom,
    s_uom, 
    cost, 
    company_id 
  FROM p
)
PIVOT(
  ANY_VALUE(cost) 
    FOR company_id IN(1,2,3,4,5,6)
    )
ORDER BY code;
