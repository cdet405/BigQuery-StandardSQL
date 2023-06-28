-- ** Old Instance - Obsolete **
-- Created by Chad Detwiler last Rev 2022-09-23
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
WITH br AS(
  SELECT 
    'NAME' Brand, 
    invoice_number, 
    invoice_date, 
    SUM(l.amount) amount 
  FROM 
    `PROJECTID.DATASET-OLD.account_invoices`, 
    UNNEST(lines) l 
  WHERE 
    invoice_date IN(ty, ly) 
    AND invoice_type = 'out' 
    AND state IN('paid', 'posted') 
    AND l.quantity > 0 
  GROUP BY 
    invoice_number, 
    invoice_date
) 
SELECT 
  Brand, 
  invoice_date TYLY_Date, 
  SUM(amount) Revenue 
FROM 
  br 
GROUP BY
  Brand, 
  invoice_date


