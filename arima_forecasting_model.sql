-- create machine learning arima forecasting model
create or replace model `project.dataset.xForecastModel`
options(
  model_type='ARIMA_PLUS',
  time_series_data_col='sales',
  time_series_id_col='product_code',
  time_series_timestamp_col='day',
  data_frequency='DAILY',
  holiday_region='US',
  clean_spikes_and_dips=true,
  seasonalities=['QUARTERLY'],
  trend_smoothing_window_size=90,
  max_time_series_length=90
) as 
-- base sales data
with s as(
  select
    product_code,
    quantity,
    order_date
  from `project.dataset.v_salesOrders`
  where company_name ='x' 
  and order_date >= '2020-01-01'
  and upper(product_code) not like 'SHIP%'
  and product_code != 'MISC'
),
-- summed sales by day
ss as(
  select 
    product_code,
    sum(quantity) tot,
    order_date
  from s 
  group by 1,3
),
-- calculate bom usuage of sales
xb AS(
  select 
    product_code,
    input,
    quantity,
    tot,
    tot * manifest.convert_uom(quantity,UoM,d_uom) itot, --quantity itot --
    order_date
  from ss
  left join(
    -- fetch exploded boms
    select
      boom.*,
      iu.d_uom,
      iu.p_uom,
      iu.s_uom,
      iu.w_uom
    from `project.dataset.explodedBOM` boom
    left join(
      -- fetch product uom settings
      select 
        code, 
        default_uom_name d_uom, 
        purchase_uom_name p_uom, 
        sale_uom_name s_uom,
        weight_uom_name w_uom  
      from `project.dataset.products` 
      where active = true 
      ) iu on iu.code = boom.input
    where 
    (
      topSkuBotF = true 
      and 
      BotF = true
    ) 
    and
    (
      sequence is null
      or 
      sequence = 10
    )
    -- if velocity forecast use this
    /*
    where
    (
      sequence is null
      or 
      sequence = 10
    )
    */
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
  order_date
),
-- add sku totals as parent and child
u as(
  select 
    input product_code, 
    itot tot, 
    order_date
  from xb 
  union all 
  select 
    product_code, 
    tot, 
    order_date
  from ss
),
-- fetch active products
ap as(
  select 
    code, 
    variant_name, 
    active 
  from `project.dataset.products` 
  where active=true
) 
-- final data set for model
select  
  product_code,
  sum(tot) sales,
  cast(order_date as timestamp) day
from u 
inner join ap on code = product_code
group by 1,3
order by 
  3 desc,
  1 asc
