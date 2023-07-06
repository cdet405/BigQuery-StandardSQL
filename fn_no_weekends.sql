-- planned_date will sometimes assign to a weekend. this prevents that.
-- as well as pushing planned_date +1 day when assigned after cutoff
-- added calendar reference table for restricted days i.e holidays/nonworking
CREATE OR REPLACE FUNCTION manifest.fn_no_weekends(
  dateValue DATE, 
  ts TIMESTAMP
) RETURNS DATE AS (
  (
    WITH x AS(
      SELECT
        dates,
        resume_date
      FROM manifest.calendar
    ),
    d AS(
      SELECT
        CASE
            WHEN 
              FORMAT_DATE(
                '%A', 
                DATE(
                  dateValue
                )
              ) = 'Saturday' 
                THEN 
                  DATE(
                    dateValue 
                    + INTERVAL 3 DAY
                  )
            WHEN 
              FORMAT_DATE(
                '%A', 
                DATE(
                  dateValue
                )
              ) = 'Sunday' 
                THEN 
                  DATE(
                    dateValue 
                    + INTERVAL 2 DAY
                 )
            WHEN
              (
                FORMAT_DATE(
                  '%A', 
                  DATE(
                    dateValue
                  )
                ) = 'Friday' 
                AND 
                  CAST(
                    FORMAT_DATETIME(
                      '%k', 
                      DATETIME(
                        TIMESTAMP(
                          ts
                        ), 
                       'America/New_York'
                      )
                   ) 
                   AS INT64
                 ) 
                >= 14
              ) 
              THEN 
                DATE(
                  dateValue 
                  + INTERVAL 3 DAY
                )
            WHEN 
              (
                (
                  DATE(
                    dateValue
                  ) 
                  = 
                  DATE(
                    ts
                  )
               ) 
                AND 
                  CAST(
                    FORMAT_DATETIME(
                      '%k', 
                      DATETIME(
                        TIMESTAMP(
                          ts
                        ), 
                       'America/New_York'
                      )
                    ) 
                   AS INT64
                  ) 
                >= 14
              ) 
              THEN 
                DATE(
                  dateValue 
                  + INTERVAL 1 DAY
                )
            ELSE 
              DATE(
                dateValue
              )
      END output
    )
    SELECT
      COALESCE(
        resume_date,
        output
      ) AS dateValue
    FROM d
    INNER JOIN x ON x.dates = d.output
  )
);
