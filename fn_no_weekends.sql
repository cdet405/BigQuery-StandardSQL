-- planned_date will sometimes assign to a weekend. this prevents that.
-- will need to pull in assigned_at in addition to planned_date to hit friday night. 
CREATE OR REPLACE FUNCTION `project.dataset.fn_no_weekends`(dateValue DATE, ts TIMESTAMP) 
RETURNS DATE AS (
  CASE WHEN FORMAT_DATE('%A',DATE(dateValue)) = 'Saturday' THEN DATE(dateValue + INTERVAL 3 DAY)
       WHEN FORMAT_DATE('%A',DATE(dateValue)) = 'Sunday' THEN DATE(dateValue + INTERVAL 2 DAY)
       WHEN (FORMAT_DATE('%A',DATE(dateValue)) = 'Friday' AND CAST(FORMAT_DATETIME('%k',DATETIME(TIMESTAMP(ts), 'America/New_York')) AS INT64) >= 15)THEN DATE(dateValue + INTERVAL 3 DAY)
       ELSE DATE(dateValue)
  END
);
 
