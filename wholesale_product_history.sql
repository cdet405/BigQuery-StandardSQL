-- 2023-07-25 CD 
-- Product Sales/Consumption History for target wholesalers
-- change from ref in ss to s for full history (sws for targeted wholesalers) 
with 
-- target wholesale customers
ws as(
  select 
    id,
    name,
    code,
  from `project.dataset.contacts` 
  where code IN(
    '24001',
    '24057',
    '24001',
    '43447',
    '42426',
    '9371',
    '43402'
    )
),
-- sales history
s as(
  select
    product_code,
    product_variant_name,
    quantity,
    order_date,
    customer_code,
    customer_name
  from `project.dataset.sales_orders` s, 
  unnest(lines) l
  where order_date >= '2023-01-01'
    and l.line_type = 'sale' 
    and s.state in(
      'processing', 
      'done'
      )
    and product_code != 'Shipping'
),
--sales history filtered to wholsesale
sws as(
  select 
    s.*
  from s 
  inner join ws on s.customer_code = ws.code
),
-- sum sales
ss as(
  select 
    product_code,
    sum(quantity) tot,
    extract(ISOWEEK from order_date) week,
    extract(ISOYEAR from order_date) year
  from sws -- change to s for everything
  where product_code != 'Shipping'
  group by 
    product_code, 
    week, 
    year
), 
-- Fetch Exploded BOM Data form called routine & make it math
xb as(
  select 
    product_code,
    input,
    quantity,
    tot,
    tot * func.convert_uom(quantity,UoM,d_uom) itot, --quantity itot --
    week,
    year
  from ss
  left join(
    -- join exploded bom table
    select
      boom.*,
      iu.d_uom,
      iu.p_uom,
      iu.s_uom,
      iu.w_uom
    from `project.dataset.explodedBOM` boom
    left join(
     -- join product unit of messurements for conversions 
      select 
        code, 
        default_uom_name d_uom, 
        purchase_uom_name p_uom, 
        sale_uom_name s_uom,
        weight_uom_name w_uom  
      from `project.dataset.products` 
      where active = true 
    ) iu on iu.code = boom.input
    where (
      topSkuBotF = true 
      and BotF = true
      ) -- << Both top and level BotF for forecast
    -- remove ^ for velocity, change the 'and' below to where 
    and (
      sequence is null
      or sequence = 10
    )
  ) xx on xx.topSku = product_code
  group by 
    product_code, 
    input, 
    quantity, 
    UoM, 
    d_uom, 
    p_uom, 
    s_uom,
    tot, 
    itot, 
    week, 
    year
),
-- combines total consumption with total sales (parent and child)
u as(
  select 
    input product_code, 
    itot tot, 
    week,
    year
   -- ,'xb' dataSource -- used for debugging
  from xb 
  union all
  select 
    product_code, 
    tot, 
    week,
    year
   -- ,'s(ws)' dataSource  -- used for debugging
  from ss
),
-- fetch product's active field 
ap as(
  select 
    code, 
    variant_name, 
    active 
  from `project.dataset.products` 
) 
-- Final output to copy pasta into forecast sheet
select  
 product_code,
 sum(tot) qty,
 week,
 year,
 concat(
  'c',
  week,
  'd',
  year
  ) key
from u 
left join ap on code = product_code
where product_code is not null
and active = true -- may need to remove in future for adding supersession history
group by 
  product_code, 
  week, 
  year, 
  key
having qty > 0
order by 
  year desc,
  week desc, 
  product_code desc
;
