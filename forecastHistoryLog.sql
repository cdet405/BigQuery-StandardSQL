/*
this will need updated when schema changes to include outliers / seasonal index / iso year? 
*/
-- data source for forecast accuracy scorecard
WITH fh AS(
  SELECT
    *, 
    row_number() 
      OVER (
        PARTITION BY 
          product_code,
          weekNum 
        ORDER BY 
          runDate
      ) revNum
  FROM `PROJECT_ID.DATASET.forecastVelocityStg`
)
-- Final Forecast History Data Set
SELECT
  fh.product_code,
  fh.weekNum,
  fh.qty,
  fh.weekPeriod,
  fh.revNum,
  fh.runDate 
FROM fh
 -- This Join Filters Data Set forecast numbers by latest upload per product per weekNum
 -- aka where the magic happens
 JOIN(
   SELECT
     product_code,
     weekNum,
     MAX(revNum) lastRev
   FROM fh
  GROUP BY 
    product_code, 
    weekNum
 ) mfh 
     ON fh.product_code = mfh.product_code AND fh.weekNum = mfh.weekNum AND fh.revNum = mfh.lastRev
ORDER BY  
  product_code, 
  weekNum, 
  revNum 
