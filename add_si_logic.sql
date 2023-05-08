-- testing how to transform si values to be loaded into table for report
-- base table
with b as(
  select * from `project.dataset.vfv8si`
),
-- distinct records 
d as(
  select 
   --distinct
    sku,
    sznIndex,
    min(weekPeriod) mwp
  from b
  group by sku, sznIndex
  
),
-- resolve week 
rw as(
  select 
   distinct 
    week, 
    weekPeriod 
  from b
),
-- prepped dataset 
pd as(
select 
  d.*, 
  rw.week, 
  concat(
    'week:',
    rw.week,
    ' seasonal_index:',
    round(
      d.sznIndex,
      3
    )
  ) infoSI 
from d
left join rw on rw.weekPeriod=d.mwp
)
-- end result that would need to inserted to table
select 
  sku,
  string_agg(infoSI,' | ') printSI
from pd
group by sku
order by sku

