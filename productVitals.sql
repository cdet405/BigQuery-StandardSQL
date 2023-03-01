-- Product Vitals 
WITH attr AS( 
  SELECT 
    DISTINCT p.code, 
    CASE WHEN is_gift_card = TRUE THEN 1
         WHEN p.code IN('SS20','EMPTYBIN','BININSERTS','FAIRE-COMMISSIOON') THEN 1
         WHEN IFNULL(is_consumable,FALSE) = TRUE THEN 1
         WHEN LOWER(p.variant_name) LIKE '% label%' THEN 1 
         WHEN LOWER(p.variant_name) LIKE '% sticker%' THEN 1
         WHEN LOWER(p.variant_name) LIKE '% card%' THEN 1
         WHEN LOWER(p.variant_name) LIKE '%shipping%' THEN 1
         WHEN LOWER(p.variant_name) LIKE '% comission%' THEN 1
         WHEN LOWER(p.variant_name) LIKE '%discount%' THEN 1
         WHEN LOWER(p.variant_name) LIKE '% tax%' THEN 1
         WHEN LOWER(p.variant_name) LIKE '% credit%' THEN 1
         WHEN LOWER(p.variant_name) LIKE '%service%' THEN 1
         WHEN LOWER(p.variant_name) LIKE '% box%' THEN 1
         WHEN LOWER(p.variant_name) LIKE '%points' THEN 1
         WHEN LOWER(p.variant_name) = 'tooling' THEN 1
         WHEN LOWER(p.variant_name) LIKE 'devtest%' THEN 1
         WHEN LOWER(p.variant_name) LIKE '% test%' THEN 1
         ELSE 0 
    END AS LSBNTO,
    CASE WHEN EXISTS (
      SELECT 
        DISTINCT code 
      FROM 
        `PROJECT.HOST.products` 
        LEFT JOIN UNNEST(listings) l 
      WHERE 
        (
          code  IN(
            SELECT 
              DISTINCT code 
            FROM 
              `PROJECT.HOST.products` 
              LEFT JOIN UNNEST(listings) l 
            WHERE 
              l.state IN('failed','draft','disabled') 
              AND active = TRUE
          ) 
          AND
          code NOT IN(
            SELECT 
              DISTINCT code 
            FROM 
              `PROJECT.HOST.products` 
              LEFT JOIN UNNEST(listings) l 
            WHERE 
              l.state = 'active'
              AND active = TRUE
          )
        ) 
      AND active = TRUE 
      AND code = p.code
    ) THEN 1 ELSE 0 END AS previouslySalable, 
    CASE WHEN EXISTS (
      SELECT 
        DISTINCT code 
      FROM 
        `PROJECT.HOST.products` 
        LEFT JOIN UNNEST(listings) l 
      WHERE 
        (
          l.id IS NULL 
          OR code NOT IN(
            SELECT 
              DISTINCT code 
            FROM 
              `PROJECT.HOST.products` 
              LEFT JOIN UNNEST(listings) l 
            WHERE 
              l.state = 'active' 
              AND active = TRUE
          ) 
          OR is_consumable = TRUE -- This is Correct because its case returns salabe when false
        ) 
        AND active = true 
        AND code = p.code
    ) THEN 0 ELSE 1 END AS currentlySalable, 
    CASE WHEN EXISTS (
      SELECT 
        input 
      FROM 
        `PROJECT.HOST.explodedBOM` 
      WHERE 
        input = p.code
    ) THEN 1 ELSE 0 END as isInput, 
    CASE WHEN EXISTS (
      SELECT 
        output 
      FROM 
        `PROJECT.HOST.explodedBOM` 
      WHERE 
        output = p.code
    ) THEN 1 ELSE 0 END as isOutput, 
    CASE WHEN EXISTS (
      SELECT 
        product_code 
      FROM 
        `PROJECT.HOST.product_suppliers` ps 
      WHERE 
        ps.product_code = p.code
    ) 
    OR EXISTS (
      SELECT 
        code 
      FROM 
        `PROJECT.HOST.product_suppliers` ps 
      WHERE 
        ps.code = p.code
    ) THEN 1 ELSE 0 END AS purchasable 
  FROM 
    `PROJECT.HOST.products` p 
  WHERE 
    p.active = TRUE
), i AS(
  SELECT 
    product_code, 
	SUM(quantity_on_hand) oh 
  FROM `PROJECT.HOST.inventory_current` 
  GROUP BY product_code
),
-- product_code impact, how many boms it's apart of
impact AS(
  SELECT DISTINCT 
  code, 
  variant_name,
  COUNT(
    DISTINCT IF(
      input=code,
      bomID,
      NULL
    )  -- input at current level
  ) directInputOfBoms, 
  COUNT(
    DISTINCT IF(
      input=code,
      topBomID
      ,NULL
    ) -- input by association outside leveld bom
  ) indirectInputOfBoms,
  COUNT(
    DISTINCT IF(
      output=code,
      bomID
      ,NULL
    ) -- output of current level
  ) directOutputOfBoms,
  COUNT(
    DISTINCT IF(
      output=code,
      topBomID,
      NULL
    ) -- output by association outside leveld bom
  ) indirectOutputOfBoms,
  COUNT(
    DISTINCT IF(
      (
        output=code OR input=code
      ),
      topBomID,
      NULL
    ) -- total bom count product comes in contact with
  ) touchesBoms,
  FROM `PROJECT.HOST.products` p
  CROSS JOIN `PROJECT.HOST.explodedBOM` 
  WHERE active = TRUE
  GROUP BY code, variant_name
  #HAVING touchesBoms > 0 -- Filters out products not associated with any bom
)
SELECT
  code,
  variant_name,
  LSBNTO,                  -- bool  | Label, Sticker, Box, Card, Bin, TestSku, Service Sku, NonTang, Other
  currentlySalable,        -- bool  | Has Active Listing
  previouslySalable,       -- bool  | Has Deactived, Failed or Draft Listing
  purchasable,             -- bool  | product has a supplier
  isInput,                 -- bool  | product is an Input
  isOutput,                -- bool  | product is an Output
  directInputOfBoms,       -- count | Number of BOM's product is input at Current Level
  indirectInputOfBoms,     -- count | Number of BOM's product is input indriectly At Any Level
  directOutputOfBoms,      -- count | Number of BOM's product is output at Current Level
  indirectOutputOfBoms,    -- count | Number of BOM's product is output indriectly At Any Level
  touchesBoms,             -- count | Total Number of BOM's product is associated with | when 0 product should be purchasable or salable
FROM attr
JOIN impact USING (code)
