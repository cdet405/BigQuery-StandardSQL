-- test logic to get format prepped to add si to vfv% reports
with t as(
  select * from `project.dataset.testvf`
)
select 
 distinct
  sku, 
  mwp,
  sznIndex 
from t
inner join(
  select
    sku,
    min(weekPeriod) mwp,
    sznIndex
    from t
    group by sku, sznIndex
) x using (sku,sznIndex)
order by sku, mwp
