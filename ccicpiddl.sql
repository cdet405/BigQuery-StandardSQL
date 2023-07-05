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
-- create working table 
create table manifest.tmpFix(
  x float64,
  y int64
);
-- load data for update 
load data into manifest.tmpFix
from files(
  format = 'CSV',
  skip_leading_rows = 1,
  uris = ['gs://bucket/folder/fix.csv']
);
-- set fixed values 
merge manifest.ccicpi p
using manifest.tmpFix s
on p.sid = s.y
when matched 
then update
set p.cpi_mm = s.x;
-- clean up 
drop table if exists manifest.tmpFix;
