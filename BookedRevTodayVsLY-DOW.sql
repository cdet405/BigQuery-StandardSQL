-- updated for current instance 2023-06-28 CD
-- Note: Not Enough Data in Current Instance for ly to Work (<1 Year of Data)
-- added: n_months_back while ly data is absent
-- n (number of months back) could be set as an @param in datastudio, replace instances of n to @n
-- ty could also be a datastudio param @ty (follow same steps as n to @n)
-- ty = Today, ly = the same day of the week last year as ty

DECLARE ty, ly, n_months_back DATE;
DECLARE n INT64; -- remove for datastudio version
SET              -- remove for datastudio version
  n = 1;         -- remove for datastudio version
-- set todays date as variable
SET 
  ty = (
    CURRENT_DATE()
);
-- generate last years date (same day of week)
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
/* -- Unintended Result 
SET n_months_back = (
  DATE_SUB(
    DATE_SUB(
      ty, INTERVAL n MONTH
    ),
    INTERVAL (
      MOD(
        EXTRACT(
          DAYOFWEEK FROM ty
        ) 
        - 1 + 7,
       7
      )
    ) DAY
  )
);
*/
-- generates date n months back (same day of week)
SET n_months_back = (
  SELECT 
    DATE_ADD(
      DATE_TRUNC(
        DATE_SUB(
          ty, INTERVAL n MONTH -- change n to @n for datastudio
        ), 
        WEEK(
          SUNDAY
        )
      ), 
      INTERVAL (
        EXTRACT(
          DAYOFWEEK FROM ty
        )
        - 1
      ) 
     DAY
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
    invoice_date IN(ty, ly, n_months_back) 
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
