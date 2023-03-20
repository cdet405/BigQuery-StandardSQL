-- Grab All Historic Sales 
with s as(
  select 
    company_name,
    order_id,
    order_reference,
    order_date,
    product_code,
    channel_name,
    amount
  from `project.dataset.v_salesOrders`
  where company_name = 'company_name'
),
-- agg sales by month
sm as (
  select
    company_name,
    extract(year from order_date) year,
    extract(month from order_date) month,
    sum(amount) amt
  from s
  group by company_name, year, month
),
-- grab cci by month
cci as(
  select 
    location,
    time,
    value,
    cast(split(time,'-')[offset(0)] as int64) year,
    cast(split(time,'-')[offset(1)] as int64) month
  from `project.dataset.cci`
),
-- union monthly datasets
u as(
  select
    company_name name,
    year,
    month,
    amt value
  from sm
  union all
  select
    location name,
    year,
    month,
    value
  from cci
)
-- final output with date field for datastudio chart
select *, 
  DATE(CONCAT(u.year,'-',if(length(cast(u.month as string))<2,concat('0',u.month),cast(u.month as string)),'-01')) dt 
from u
