-- Load Raw Forecast Files into Raw Tables

load data into manifest.vfv10
from files (
  format = 'CSV',
  skip_leading_rows = 1,
  uris = ['gs://bucket/folder/vfv10.csv']
);

load data into manifest.vfv10si
from files (
  format = 'CSV',
  skip_leading_rows = 1,
  uris = ['gs://bucket/folder/vfv10si.csv']
);
