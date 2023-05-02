--* version 2 *--
-- fetch product data
with p as(
  select 
    code,
    purchase_uom_name p_uom,
    default_uom_name d_uom,
    sale_uom_name s_uom,
    active,
    c.cost,
    c.costing_method method,
    c.company_name,
    c.company_id,
    c.currency_code
  from `project.data.products`
  ,unnest(costs) c 
),
-- piv p to retain all company variations
piv as(
  select 
    * 
  from(
    select 
      code, 
      active,
      p_uom,
      d_uom,
      s_uom, 
      cost, 
      company_id 
    from p
  )
  pivot(
    any_value(
      cost
    ) 
    for company_id in(
      1,2,3,4,5,6
    )
  )
order by code
), 
-- unpiv for future conditional joins
unpiv as(
  select 
    * 
  from piv 
  unpivot(
    cost for company_id in(
      _1,_2,_3,_4,_5,_6
    )
  )
),
-- fix company_id from unpiv
funpiv as(
  select 
    * except(company_id), 
    cast(
      right(
        company_id,
        1
      ) 
      as int64
    ) company_id 
  from unpiv 
  order by code
) 
select 
  * 
from funpiv
order by code
