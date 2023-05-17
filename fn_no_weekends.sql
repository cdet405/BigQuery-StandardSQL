CREATE OR REPLACE FUNCTION `project.dataset.fn_no_weekends`(dateValue DATE) 
RETURNS DATE AS (
-- planned_date set by system doesnt respect user level date params
  CASE WHEN FORMAT_DATE('%A',DATE(dateValue)) = 'Saturday' THEN DATE(dateValue + INTERVAL 2 DAY)
       WHEN FORMAT_DATE('%A',DATE(dateValue)) = 'Sunday' THEN DATE(dateValue + INTERVAL 1 DAY)
       ELSE DATE(dateValue)
  END
);
