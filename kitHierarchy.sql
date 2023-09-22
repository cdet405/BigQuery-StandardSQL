-- 20230922 CD Kit Hierarchy
-- loop through boms
WITH recursive rpl AS (
  SELECT 
    0 AS level, 
    root.parentProductID, 
    root.childProductID, 
    root.qtyRequired, 
    root.parentProductID AS topParentProductID 
  FROM 
    `dev_cd.boms` root 
  UNION ALL 
  SELECT 
    parent.level + 1, 
    child.parentProductID, 
    child.childProductID, 
    child.qtyRequired, 
    parent.topParentProductID 
  FROM 
    rpl parent, 
    `dev_cd.boms` child 
  WHERE 
    parent.childProductID = child.parentProductID 
    AND parent.level < 7 -- this breaks infinite loops 
    ), 
  -- calc sublevel
rpl_with_sublevel AS (
  SELECT 
    topParentProductID, 
    level, 
    parentProductID, 
    childProductID, 
    qtyRequired, 
    CASE WHEN parentProductID != LAG(parentProductID) OVER (
      PARTITION BY topParentProductID 
      ORDER BY 
        level
    ) THEN 1 ELSE 0 END AS subLevel 
  FROM 
    rpl
) 
-- final report
SELECT 
  topParentProductID, 
  level, 
  SUM(subLevel) OVER (
    PARTITION BY topParentProductID 
    ORDER BY 
      level ROWS BETWEEN UNBOUNDED PRECEDING 
      AND CURRENT ROW
  ) AS subLevel, 
  parentProductID, 
  childProductID, 
  qtyRequired, 
FROM 
  rpl_with_sublevel 
ORDER BY 
  topParentProductID, 
  level, 
  parentProductID, 
  subLevel;
