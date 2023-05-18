-- shopify stock out stats
with ss as(
  select
    site, 
    vid, 
    sku,
    runDate,
    price, 
    available 
  from `project.dataset.shopifyScrape`
  where site not like 's%dd%s'
),
-- average retail
ar as(
  select
    vid,
    round(avg(price),2) avgRetail
  from ss 
  group by 1
),
-- last listed
ll as(
  select
  vid,
  max(runDate) lastListDate,
  from ss
  group by 1
),
-- distinct vid 
dv as(
  select 
   distinct
    vid,
    sku
  from ss
  -- removes records prior to mapping
  where sku is not null
),
-- lag dates
lg as(
  select
    site,
    vid,
    runDate,
    available,
    ifnull(
      lag(
        runDate,
        1
      ) over (
        PARTITION BY vid 
        order by runDate desc
      ),
      ll.lastListDate
    ) nxt
from ss
left join ll using (vid)
where available = true
),
-- adds datediffs
d as(
  select 
    *, 
    date_diff(
      nxt,
      runDate,
      DAY
    ) dd 
  from lg
),
-- bring in sales
s as(
  select 
    company_id,
    order_date,
    channel_name,
    product_code,
    unit_price,
    quantity
  from `fulfil-data-warehouse-227710.holdings_365.sales_orders` s
  ,unnest(lines) l   
  where order_date >= '2022-12-15'
  and l.line_type='sale' and s.state in('processing','done')
),
-- group sales
sg as(
  select
    product_code,
    order_date,
    sum(quantity) tot
  from s
  group by 1,2
),
-- first transform layer
pre as(
  select 
    dv.sku,  
    d.*,
    ar.avgRetail 
  from d 
  join dv using (vid) 
  join ar using (vid)
  where ifnull(dd,0)>1 
  order by 1,3 asc
),
-- second transform layer
mid as (
  select 
    pre.*,
    round(
      safe_divide(
        (
          select
            sum(tot)
          from sg
          where pre.sku=sg.product_code
          and(
            sg.order_date <= pre.runDate
            and sg.order_date >= pre.runDate - interval 14 day
          )
        ),
       14
      ),
    2
    ) prev14DA,
    round(
      safe_divide(
        pre.dd,
        14
      ),
     14
    ) Lratio
  from pre
) 
-- final report
select
 site,
 sku,
 vid variant_id,
 runDate sold_out_on,
 nxt next_date_instock,
 dd days_out,
 avgRetail avg_list_price,
 prev14DA pre_stock_out_daily_average_14d,
round(
   (
    dd*prev14DA
    )
  *avgRetail,
  2
 ) potential_missed_revenue
from mid 
order by 2,3

