-- used in python script for email notification
-- returns sales orders that failed to sync to erp
SELECT 
  CASE WHEN company_id = 2 THEN 'V'
       WHEN company_id = 3 THEN 'C'
       WHEN company_id = 4 THEN 'N'
       WHEN company_id = 5 THEN 'H'
       WHEN company_id = 6 THEN 'A'
       ELSE CONCAT(
        'ERR:[action=break][type=OOB][note:company_id{',
        company_id,
        '}undefined]'
      )
  END AS company_name,
  channel_name,
  order_id,
  order_reference,
  order_date,
  state,
  DATE_DIFF(
    CURRENT_DATE(),
    order_date,
    DAY
  ) days_past,
  CONCAT(
    'https://sub.domain.tld/client/#/model/sale.sale/',
    order_id,
    '?views=%5B%5B1105,%22tree%22%5D,%5B1104,%22form%22%5D%5D'
  ) order_url
FROM `project.dataset.sales_orders` 
WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 10 DAY)
AND state='failed'
ORDER BY 1,2,5
