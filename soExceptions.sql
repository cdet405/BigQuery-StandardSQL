 -- sales order exceptions used in python script
 SELECT DISTINCT
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
      CASE 
      WHEN company_id = 3 THEN 
        CONCAT(
          '<a href="',
           'https://admin.shopify.com/store/STORE-ID/orders/',
          channel_identifier,
          '">Shopify URL</a>'
        )
      WHEN company_id = 5 THEN
       CONCAT(
          '<a href="',
           'https://admin.shopify.com/store/STORE-ID/orders/',
          channel_identifier,
          '">Shopify URL</a>'
        )
      WHEN company_id = 2 THEN
       CONCAT(
          '<a href="',
           'https://admin.shopify.com/store/STORE-ID/orders/',
          channel_identifier,
          '">Shopify URL</a>'
        )
      WHEN company_id = 4 THEN
       CONCAT(
          '<a href="',
           'https://admin.shopify.com/store/STORE-ID/orders/',
          channel_identifier,
          '">Shopify URL</a>'
        )
      WHEN company_id = 6 THEN
       CONCAT(
          '<a href="',
          'https://admin.shopify.com/store/STORE-ID/orders/',
          channel_identifier,
          '">Shopify URL</a>'
        )
        ELSE NULL
      END AS shopify_order_link,
      order_id,
      order_reference,
      SUM(
        amount
        ) OVER (
          PARTITION BY 
            order_id
      ) order_value,
      order_date,
      'Exception' as state,
      DATE_DIFF(
        CURRENT_DATE(),
        order_date,
        DAY
      ) days_past,
      CONCAT(
        '<a href="',
        'https://sub.domain.tld/model/modelCat.modelName/',
        order_id,
        '?views=123456,%22tree%22%5D,%5B1104,%22form%22%5D%5D',
         '">ERP URL</a>'
      ) erp_order_link
    FROM `project.dataset.sales_orders` 
	, UNNEST(lines) l
    WHERE (
		state = 'draft' 
		AND order_date IS NOT NULL 
		AND order_reference IS NOT NULL 
		AND order_number IS NULL
	)
    ORDER BY 
	  6 desc, 
	  1 asc
	  ;
    
