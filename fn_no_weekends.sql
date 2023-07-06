-- planned_date will sometimes assign to a weekend. this prevents that.
-- as well as pushing planned_date +1 day when assigned after cutoff
-- added single day override (bandaid while working on a solution for holidays) 
CREATE OR REPLACE FUNCTION manifest.fn_no_weekends(
  dateValue DATE, 
  ts TIMESTAMP
)
RETURNS DATE AS (
  IF(
    (
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
                dateValue + INTERVAL 3 DAY
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
                dateValue + INTERVAL 2 DAY
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
              ) AS INT64
            ) 
            >= 14
          )
            THEN 
              DATE(
                dateValue + INTERVAL 3 DAY
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
                  dateValue + INTERVAL 1 DAY
                )
          ELSE 
            DATE(
              dateValue
            )
       END
    )
    = '2023-07-04', -- temporary fix / override date
    '2023-07-06', -- temporary fix / replacement date 
        (
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
                dateValue + INTERVAL 3 DAY
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
                dateValue + INTERVAL 2 DAY
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
              ) AS INT64
            ) 
            >= 14
          )
            THEN 
              DATE(
                dateValue + INTERVAL 3 DAY
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
                  dateValue + INTERVAL 1 DAY
                )
          ELSE 
            DATE(
              dateValue
            )
      END
    )
  )
);  
