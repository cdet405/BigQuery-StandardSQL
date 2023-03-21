-- demand rev vs vix
with v as(
  select * 
  from `project.dataset.vix`
),
s as(
  select 
    company_name,
    order_id,
    order_reference,
    order_date,
    product_code,
    channel_name,
    amount
  from `project.dataset.v_salesOrders`
  where company_name = 'theCompanyName'
),
ssd as(
  select
    company_name,
    order_date,
    SUM(amount) amt
  from s 
  group by company_name, order_date
),
main as(
  select
    company_name,
    order_date,
    amt,
    vix_open,
    vix_high,
    vix_low,
    vix_close
  from ssd
  inner join v on DATE(ssd.order_date) = DATE(v.vix_date)
)

select * from main
order by date(order_date) desc
