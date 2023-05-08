-- //TODO: update vfv% table_name @ line34 to newest
-- Deactivate Current Records
UPDATE `project.dateset.forecastVelocityStg`
SET active = false
WHERE active = true
;
-- Insert New Records
INSERT INTO `project.dateset.forecastVelocityStg`
(
  company_name,
  product_code,
  weekNum,
  qty,
  weekPeriod,
  runDate,
  active,
  mqty,
  confidencyLevel,
  previousActual,
  sid
)
SELECT 
  'company' AS company_name, 
  sku AS product_code, 
  week AS weekNum, 
  qty, 
  weekPeriod, 
  runDate, 
  true AS active,
  mqty,
  cL AS confidencyLevel,
  LTM26 AS previousActual,
  sync_id AS sid
FROM `project.dateset.vfv8v2` -- <--- *change to newest vfv table*
;
-- if MAX(fV.pd) = today rebuild call aborts 
-- clear all pd records, bypass exit routine
UPDATE `project.dateset.forecastVelocity`
  SET pd = NULL
WHERE 1=1;
-- Call for Rebuild
CALL `project.dateset.spForecastVelocity`();
