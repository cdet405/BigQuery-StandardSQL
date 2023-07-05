-- create table
create or replace table manifest.ccicpi(
  product string,
  period string,
  value_cci float64,
  value_cpi float64,
  cpi_mm float64,
  fred_food_cpi float64,
  sales_qty int64,
  date date,
  sid int64 options(description='sequence id by product & period'),
  pid int64 options(description='id given to a sku as it enters loop'),
  load_ts date default current_date()
);
-- insert csv to table 
load data into manifest.ccicpi
from files(
  format = 'CSV',
  skip_leading_rows = 1,
  uris = ['gs://bucket/folder/ccicpibase.csv']
);
