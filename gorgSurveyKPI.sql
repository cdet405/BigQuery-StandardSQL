-- Will need Company, Channel and User Added | Blocked by ticket data pipeline
WITH surv AS(
  SELECT  
    *,
    EXTRACT(YEAR FROM scored_datetime) yy,
    EXTRACT(MONTH FROM scored_datetime) mm,
    FORMAT_DATETIME("%Y-%m", DATETIME(scored_datetime)) period,
  FROM gorgSurvey 
  WHERE scored_datetime IS NOT NULL
),
score AS(
  SELECT 
    yy,
    mm,
    period,
    AVG(score) OVER p avgRating,
    MIN(score) OVER p minRating,
    MAX(score) OVER p maxRating,
    COUNT(score) OVER p countRating,
    COUNTIF(score=1) OVER p oneStar,
    COUNTIF(score=2) OVER p twoStar,
    COUNTIF(score=3) OVER p threeStar,
    COUNTIF(score=4) OVER p fourStar,
    COUNTIF(score=5) OVER p fiveStar,
  FROM surv
  WINDOW p AS(
    PARTITION BY
      yy,
      mm
  )
)
SELECT 
 DISTINCT
  *
FROM score
ORDER BY 
  1 DESC, 2 DESC
;
