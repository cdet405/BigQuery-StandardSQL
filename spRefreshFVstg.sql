CREATE OR REPLACE PROCEDURE `PROJECT.DATASET.spRefreshFVstg`(tableName STRING)
BEGIN 
DECLARE deactivate, import, build, location STRING;
SET location = CONCAT("`PROJECT.DATASET.",tableName,"`");

SET deactivate = FORMAT(
  """
UPDATE `PROJECT.DATASET.forecastVelocityStg`
SET active = false
WHERE active = true; 
  """
);

SET import = FORMAT(
  """
  INSERT INTO `PROJECT.DATASET.forecastVelocityStg`
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
FROM %s
  """
, location);

SET build = FORMAT(
  """
  UPDATE `PROJECT.DATASET.forecastVelocity`
  SET pd = NULL
WHERE 1=1;
  """
);

EXECUTE IMMEDIATE deactivate;
EXECUTE IMMEDIATE import;
EXECUTE IMMEDIATE build;
CALL `PROJECT.DATASET.spForecastVelocity`();

END;
