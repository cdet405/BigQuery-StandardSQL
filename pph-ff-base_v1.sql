/* 
2023-07-26 CD version 1.01
pph project - ff base data
* rough proof of concept model * 
figure out whether summing etc can be done in DS
if not than dash may need to be multi source
*/
-- ff shipment data
with cs as (
  select 
    number,
    state,
    fulfil_strategy,
    shipped_date,
    shipped_at,
    picked_at,
    packed_at,
    planned_date,
    assigned_time,
    warehouse,
    warehouse_code,
    packages_count,
    picker,
    packer,
    shipper,
    line_items_count
/* line_items_count should work for now. Ideally we need to 
loop through all the shipment lines, and expand item count when item is botf
since they would have to also pick the children. As well as Identifying
'special care skus' for CS interventioned orders.
*/
  from `project.dataset.shipments`
  where warehouse_type = 'operated'
  and shipped_date >= '2023-05-01'
  -- Since a shipped date exist - all records should be in a state = 'done'
)
/*
pick/pack/ship counts record occurence (shipments)
while items, is a sum of line items on said shipments
items being parent sku only
*/
select 
  shipped_date,
  warehouse_code,
  coalesce(
    picker,
    packer,
    shipper
  ) user,
  countif(
    picker=coalesce(
      picker,
      packer,
      shipper
    )
  ) pick,
  countif(
    packer=coalesce(
      picker,
      packer,
      shipper
    )
  ) pack,
  countif(
    shipper=coalesce(
      picker,
      packer,
      shipper
    )
  ) ship,
  sum(line_items_count) items
from cs
group by 
  1,
  2,
  3
order by 
  1 desc, 
  2 asc,
  3 asc
;
