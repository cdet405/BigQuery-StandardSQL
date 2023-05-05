-- test logic to get format prepped to add si to vfv% reports
with t as(
  select * from `chaddata-359115.manifest.testvf`
), t2 as(
select 
 distinct
  sku, 
  mwp,
  sznIndex,
  concat('w:',mwp,' | ','s:',sznIndex) cd
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
)
select
sku,
string_agg(cd, ', ') si_info
from t2
group by sku
