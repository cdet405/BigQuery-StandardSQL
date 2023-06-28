-- updated for current instance 2023-06-28 CD
-- Note: Not Enough Data in Current Instance to Work (<1 Year of Data)
-- ty = Today, ly = the same day of the week last year as ty

DECLARE ty, ly DATE;
SET 
  ty = (
    CURRENT_DATE()
  );
SET 
  ly = (
    DATE_ADD(
      DATE_ADD(ty, INTERVAL -1 YEAR), 
      INTERVAL (
        EXTRACT(
          WEEK 
          FROM 
            ty
        ) * 7 + EXTRACT(
          DAYOFWEEK 
          FROM 
            ty
        )
      ) - (
        EXTRACT(
          WEEK 
          FROM 
            DATE_ADD(ty, INTERVAL -1 YEAR)
        ) * 7 + EXTRACT(
          DAYOFWEEK 
          FROM 
            DATE_ADD(ty, INTERVAL -1 YEAR)
        )
      ) DAY
    )
  );
WITH aibr AS(
  SELECT 
    company_id, 
    invoice_number, 
    invoice_date, 
    SUM(l.amount) amount 
  FROM 
    `PROJECT.DATASET.account_invoices`, 
    UNNEST(lines) l 
  WHERE 
    invoice_date IN(ty, ly) 
    AND invoice_type = 'out' 
    AND state IN('paid', 'posted') 
    AND l.quantity > 0 
  GROUP BY 
    1,
    2,
    3
) 
SELECT 
  company_id, 
  invoice_date TYLY_Date, 
  SUM(amount) Revenue 
FROM 
  aibr 
GROUP BY
  1,
  2
ORDER BY 
  1 ASC,
  2 DESC
;
