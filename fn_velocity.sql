-- Table Function That Returns Product Velocity Using Variables d = days prior, and w = Bom Level Filter.
-- Variables are set in Data Studio By User on the fly
CREATE OR REPLACE TABLE FUNCTION `PROJECT.HOST.velocity`(d INT64, w ARRAY<STRING>) AS(
	-- Fetch Sales Data
  WITH s AS(
    SELECT
      product_code,
      product_variant_name,
      CASE WHEN company_id = 1 THEN 'comapanyNameA'
           WHEN company_id = 2 THEN 'comapanyNameB'
           WHEN company_id = 3 THEN 'comapanyNameC'
           WHEN company_id = 4 THEN 'comapanyNameD'
           WHEN company_id = 5 THEN 'comapanyNameE'
           WHEN company_id = 6 THEN 'comapanyNameF'
         ELSE CONCAT('ERR:[CTE=s][CASE=OOB][value=company_id{',company_id,'}]')
      END AS company_name,
      channel_name,
      quantity,
      order_date
    FROM `PROJECT.HOST.sales_orders` s, UNNEST(lines) l
    WHERE order_date >= CURRENT_DATE() - INTERVAL d DAY 
    AND l.line_type = 'sale' AND s.state IN('processing', 'done')
    AND channel_name NOT LIKE '%Intercompany Transfer'
  ), 
  -- Sum Sales Data by product_code
  ss AS(
    SELECT 
      product_code,
      SUM(quantity) tot
    FROM s 
    WHERE product_code != 'Shipping'
    GROUP BY product_code
  ), 
  -- Fetch Exploded BOM, Calculate All Levels of Inputs per TopSku in SS Omitting BotF based on @w
  xb AS(
    SELECT 
      product_code,
      input,
      quantity,
      tot,
      tot * HOST.convert_uom(quantity,UoM,d_uom) itot --quantity itot --
    FROM ss
    LEFT JOIN(
      SELECT
        boom.*,
        iu.d_uom,
        iu.p_uom,
        iu.s_uom,
        iu.w_uom
      FROM `PROJECT.HOST.explodedBOM` boom
      LEFT JOIN(
        SELECT 
          code, 
          default_uom_name d_uom, 
          purchase_uom_name p_uom, 
          sale_uom_name s_uom,
          weight_uom_name w_uom  
        FROM `PROJECT.HOST.products` 
        WHERE active = true 
        ) iu ON iu.code = boom.input
       WHERE topSkuBotF IN UNNEST(HOST.string_to_bool_array(w))
	    AND(boom.sequence IS NULL OR boom.sequence = 10)
    ) xx ON xx.topSku = product_code
  GROUP BY product_code, input, quantity, UoM, d_uom, p_uom, s_uom,tot, itot
  ), 
  -- Merge Actual and Calculated Velocity
  u AS(
    SELECT 
      input product_code, 
      itot tot 
    FROM xb 
    UNION ALL 
    SELECT 
      product_code, 
      tot 
    FROM ss
  ),
  -- Fetch Product Names
  ap AS(
    SELECT 
      code, 
      variant_name 
    FROM `PROJECT.HOST.products`
  )
  -- Final Output
  -- Total up velocity, divide it down to by day, calc popCode
    SELECT
     product_code,
     variant_name,
     SUM(tot) velocity,
     ROUND(SUM(tot)/d,3) dailyAvg,
     CASE WHEN SUM(tot)/d >=.5 THEN 'A'
          WHEN SUM(tot)/d >=.2 THEN 'B'
          WHEN SUM(tot)/d >=.1 THEN 'C'
          WHEN SUM(tot)/d >  0 THEN 'D' 
          ELSE 'E' END AS popCode,   
    FROM u
    LEFT JOIN ap ON ap.code = product_code
    GROUP BY product_code, variant_name
);
