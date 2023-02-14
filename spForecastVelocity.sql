-- update tables for forecast velocity dsi for gds join
CREATE OR REPLACE PROCEDURE `REDACTED_PROJECT.REDACTED_HOST.spForecastVelocity`()
BEGIN
  -- variables for exit critera
  DECLARE rd, td, grd DATE;
  -- variables: forecast period arrays (raw & final)
  DECLARE rawfpa, ffpa ARRAY<INT64>;
  -- variables: current week, end week, start period, end period, days, weeks
  DECLARE cw, ew, sp, ep, d, w INT64; 
  -- variable: message - array info
  DECLARE m STRING;
  SET rd = (SELECT MAX(pd) FROM `REDACTED_PROJECT.REDACTED_HOST.forecastVelocity`);
  SET td = CURRENT_DATE();
  SET grd = (SELECT MAX(pts) FROM `REDACTED_PROJECT.REDACTED_HOST.forecastVelocityGroup`);
  -- exit routine on true 
IF rd = td AND grd = td THEN RETURN; END IF;
  -- current iso week
  SET cw = EXTRACT(ISOWEEK FROM CURRENT_DATE());
  -- proposed ending isoweek
  SET ew = EXTRACT(ISOWEEK FROM CURRENT_DATE() + INTERVAL 13 WEEK);
  -- starting period for forecast
  SET sp = (SELECT DISTINCT weekPeriod FROM `REDACTED_PROJECT.REDACTED_HOST.forecastVelocityStg` WHERE weekNum = cw );
  -- array of total period options available
  SET rawfpa = (SELECT ARRAY_AGG(DISTINCT weekPeriod ORDER BY weekPeriod ASC) FROM `REDACTED_PROJECT.REDACTED_HOST.forecastVelocityStg` );
  -- ending period for forecast, if proposed ending week is not available choose furthest available
  SET ep = IFNULL((SELECT DISTINCT weekPeriod FROM `REDACTED_PROJECT.REDACTED_HOST.forecastVelocityStg` WHERE weekNum   = ew ),(SELECT ARRAY_REVERSE(rawfpa)[OFFSET(0)]));
  -- resize forecast period array
  SET ffpa = (SELECT ARRAY_AGG(DISTINCT weekPeriod ORDER BY weekPeriod ASC) FROM `REDACTED_PROJECT.REDACTED_HOST.forecastVelocityStg` WHERE weekPeriod BETWEEN sp AND ep);
  -- number of weeks selected
  SET w = (SELECT ARRAY_LENGTH(ffpa)-1);
  -- number of days selected
  SET d = w*7;
  -- array info
  SET m = CONCAT('DSI Based on a ',w,' Week Forecast');

-- Future updates: Update Delete, Insert DML to Merge?
-- Wipe any existing records
DELETE `REDACTED_PROJECT.REDACTED_HOST.forecastVelocityGroup` WHERE 1=1;
DELETE `REDACTED_PROJECT.REDACTED_HOST.forecastVelocity` WHERE 1=1;

-- Insert New Forecast Array
INSERT INTO `REDACTED_PROJECT.REDACTED_HOST.forecastVelocity`
(
  company_name,
  product_code,
  weekNum,
  qty,
  weekPeriod,
  runDate,
  active,
  pd
)
SELECT
  company_name,
  product_code,
  weekNum,
  mqty as qty,
  weekPeriod,
  runDate,
  active,
  CURRENT_DATE() AS pd
FROM `REDACTED_PROJECT.REDACTED_HOST.forecastVelocityStg`
WHERE weekPeriod IN UNNEST(ffpa) AND active = true;

-- Insert New Grouped Results
INSERT INTO `REDACTED_PROJECT.REDACTED_HOST.forecastVelocityGroup`
(
  arrayInfo,
  currweek,
  endweek ,
  startperiod,
  endperiod,
  weeksConsidered,
  product_code,
  totalForecastVelocity,
  forecastDailyAverage
)
SELECT 
  m arrayInfo,
  cw currweek,
  ew endweek,
  sp startperiod,
  ep endperiod,
  w weeksConsidered,
  product_code, 
  SUM(mqty) total, 
  ROUND(SUM(mqty)/d,3) dailyAverage
FROM `REDACTED_PROJECT.REDACTED_HOST.forecastVelocityStg`
WHERE weekPeriod IN UNNEST(ffpa) AND active = true
GROUP BY product_code;

-- Eh Th-Th-Th-Th-Th-Thats all Folks!
END;