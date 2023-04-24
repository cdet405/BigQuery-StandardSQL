###################################################################################
### **** | Safety Stock Report | Method Five | version 5   2023-04-24 CD | **** ###
###################################################################################
 ### **** BEFORE EXECUTING | CHECK CALL & CTE QUERY PARAMS | ENABLE CALLS **** ###
###################################################################################
# Revision Log
 # version 5 - Hard code LT & DSD Cap (currently used bc no good way to obtain/calc leadtimes w/ current data)
 # version 4 -Created CALL to Explode BOMs & Reconciled All CALLs to be inside of l3mv()
 # version 4 -Added explode bom and only calc BotF converting to d_uom in (sql2>xb) replaces (sql2>iso(>so)>bom(>uom))
 # version 4 -Updated bom CTE to use explodedBom Table
 # version 3.1 -Changed datediff in age from month to day/30.5 to preserve decimals 
 # version 3 -Added uom conversion calc to l3mv() change in (sql2>iso(>so)>bom(>uom)) [f2]>CTE[ltms]
 # version 2 -replaced company_name with case when on companyid to return company_name (dupe nonunique company names exist)
 # version 2 -added case statement to help determine actual warehouse_name
#
# //TODO's\\
 # //TODO: [DONE] Separate BotF like Forecast (Requires Change to Routine during blend)
 # //TODO: [DONE] Fix Input UoM To Account for difference in consuming and purchasing 
 # //TODO: [LOW] Modify Stored Procedures and CTE's That use v_salesOrders; Point to 6:1 (AFTER FEB/MARCH 2023)
 # //TODO: [LOW] Review CTE Queries Periodicly (Lots of ERP Schema Changes Lately)
#
# Notes/Thoughts
 # 8056a is the only product (so far) with d_uom != p_uom d&b=oz p=lb
 # Thought about adding poqty / eta but that may be more useful in separate report tsoos/expediteReport/runningOOS
 # company_name will breakout when for new companyIDs Created After 2022-12-06
 # possible optimization opportunity, remove pr(f) po.effectivedate looks like inventory to location date not inputzone date
#
#/////////////////////////////////* ALIAS KEY *\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
 # [poh] = PO History Old Instance,| [poc] = PO History New Instance,| [blend] = poh+poc-duplicates, | [i] = Current Inventory Data
 # [age] = calcs amount of time between PO-PR etc,| [cnt] = counts instances of product+supplier/datapoints used in age
 # [pr] = All the supplier shipments matched w/ blend,| [prf] = only completed lines of pr,| [staticLT] = Lead time thats inserted in fulfil,
 # [newLT] = calcs stdev,min/max/avg lead | [qq] = Dynamic Sorting/Choosing of LT,| [bom] = outputs and respected inputs and qty   
 # [so] = Sales Orders from View,| [ss] = Main SafetyStock Query,| [ilt(i)] = Calcs Lead Time of Output based on MAX(LT) input
 # [ltms] = Last 3 Months Sales Derived from Routine,| [stdev] = Sales Data DSD/AVG/90da Calcs Derived from Routine
 # [Z] = Coefficent Service of Inverse Cumulative Normal Distribution at 90%,| [c] = Resolves company_name for most products 
 # [ap] ss source table for active products,| [ac] 1st attempt in resolving company_name
#
# Declare & Set 'z' Variable for SS Calc
DECLARE Z FLOAT64;
SET Z = 1.28; -- 90% Service Factor

#################################################################################
### **** >>>>>>>>> COMMENT OUT CALLS WHILE TESTING OTHER CTE's <<<<<<<<< **** ###
#################################################################################
# CALLS ADD 27 Seconds; Only Use when Needed (only need to run once per day)
# Runs 3 Other Routines - Adjust Variables 3 Months Before BFCM!
# Runs Routine that grabs last 3 months of sales, then adds inputs, and sums it up, stores in spResults 
CALL manifest.spRptL3MV();

# Built CTEs
# PO History qty > 0 (old instances) 
WITH poh AS(
  SELECT * FROM(
  SELECT 
  po.number,
  po.reference,
  po.purchase_date,
  po.state,
  po.warehouse,
  po.supplier_name,
  l.product_code,
  l.id,
  l.product_variant_name,
  l.quantity,
  l.uom_name,
  l.unit_price,
  "COMPANYNAME-B" company_name,
  "old" origin
  FROM `REDACTED_PROJECT.REDACTED_HOST.purchase_orders` po 
  ,UNNEST(lines) l 
  UNION ALL
  SELECT 
  po.number,
  po.reference,
  po.purchase_date,
  po.state,
  po.warehouse,
  po.supplier_name,
  l.product_code,
  l.id,
  l.product_variant_name,
  l.quantity,
  l.uom_name,
  l.unit_price,
  "COMPANYNAME-C" company_name,
  "old" origin
  FROM `REDACTED_PROJECT.REDACTED_HOST.purchase_orders` po 
  ,UNNEST(lines) l 
  UNION ALL 
  SELECT 
  po.number,
  po.reference,
  po.purchase_date,
  po.state,
  po.warehouse,
  po.supplier_name,
  l.product_code,
  l.id,
  l.product_variant_name,
  l.quantity,
  l.uom_name,
  l.unit_price,
  "COMPANYNAME-D" company_name,
  "old" origin
  FROM `REDACTED_PROJECT.REDACTED_HOST.purchase_orders` po 
  ,UNNEST(lines) l 
  UNION ALL
  SELECT 
  po.number,
  po.reference,
  po.purchase_date,
  po.state,
  po.warehouse,
  po.supplier_name,
  l.product_code,
  l.id,
  l.product_variant_name,
  l.quantity,
  l.uom_name,
  l.unit_price,
  "COMPANYNAME-E" company_name,
  "old" origin
  FROM `REDACTED_PROJECT.REDACTED_HOST.purchase_orders` po 
  ,UNNEST(lines) l 
  UNION ALL
  SELECT 
  po.number,
  po.reference,
  po.purchase_date,
  po.state,
  po.warehouse,
  po.supplier_name,
  l.product_code,
  l.id,
  l.product_variant_name,
  l.quantity,
  l.uom_name,
  l.unit_price,
  "COMPANYNAME-F" company_name,
  "old" origin
  FROM `REDACTED_PROJECT.REDACTED_HOST.purchase_orders` po 
  ,UNNEST(lines) l ) x
  WHERE NOT EXISTS (SELECT reference FROM `REDACTED_PROJECT.REDACTED_HOST.purchase_orders` WHERE reference = x.number) -- maybe add companyname?
), 
# PO History (6:1 Instance) qty > 0 
poc as(
  SELECT 
  po.number,
  po.reference,
  po.purchase_date,
  po.state,
  po.warehouse,
  po.supplier_name,
  l.product_code,
  l.id,
  l.product_variant_name,
  l.quantity,
  l.uom_name,
  l.unit_price,
  CASE WHEN company_id = 1 THEN 'COMPANYNAME-A'
     WHEN company_id = 2 THEN 'COMPANYNAME-B'
     WHEN company_id = 3 THEN 'COMPANYNAME-C'
     WHEN company_id = 4 THEN 'COMPANYNAME-D'
     WHEN company_id = 5 THEN 'COMPANYNAME-E'
     WHEN company_id = 6 THEN 'COMPANYNAME-F'
     ELSE CONCAT('ERR:[CTE=poc][CASE=OOB][value=company_id{',company_id,'}]')
  END AS company_name,
  "new" origin
  FROM `REDACTED_PROJECT.REDACTED_HOST.purchase_orders` po 
  ,UNNEST(lines) l 
),
# combineold and new instance
blend AS(
 SELECT * FROM poh
 UNION ALL 
 SELECT * FROM poc
), 
# Final PO Table
po AS( 
  SELECT * FROM blend WHERE quantity > 0 ORDER BY purchase_date DESC
),
# Determine purchase reciepts of POs from instances and blend data 
pr AS(
 SELECT  
 ss.number,
 ss.state,
 ss.effective_date,
 ss.warehouse_name,
 ss.supplier_name,
 m.product_code,
 m.state moveState,
 m.quantity,
 m.uom_name,
 m.product_default_uom_name,
 m.from_location_type,
 m.order_number,
 m.order_line_id,
 'COMPANYNAME-B' company_name,
 'old' origin
 FROM `REDACTED_PROJECT.REDACTED_HOST.supplier_shipments` ss , UNNEST(moves) m 
 WHERE m.order_number IS NOT NULL 
 UNION ALL
 SELECT  
 ss.number,
 ss.state,
 ss.effective_date,
 ss.warehouse_name,
 ss.supplier_name,
 m.product_code,
 m.state moveState,
 m.quantity,
 m.uom_name,
 m.product_default_uom_name,
 m.from_location_type,
 m.order_number,
 m.order_line_id,
 'COMPANYNAME-C' company_name,
 'old' origin
 FROM `REDACTED_PROJECT.REDACTED_HOST.supplier_shipments` ss , UNNEST(moves) m 
 WHERE m.order_number IS NOT NULL 
 UNION ALL
 SELECT  
 ss.number,
 ss.state,
 ss.effective_date,
 ss.warehouse_name,
 ss.supplier_name,
 m.product_code,
 m.state moveState,
 m.quantity,
 m.uom_name,
 m.product_default_uom_name,
 m.from_location_type,
 m.order_number,
 m.order_line_id,
 'COMPANYNAME-D' company_name,
 'old' origin
 FROM `REDACTED_PROJECT.REDACTED_HOST.supplier_shipments` ss , UNNEST(moves) m 
 WHERE m.order_number IS NOT NULL 
 UNION ALL
 SELECT  
 ss.number,
 ss.state,
 ss.effective_date,
 ss.warehouse_name,
 ss.supplier_name,
 m.product_code,
 m.state moveState,
 m.quantity,
 m.uom_name,
 m.product_default_uom_name,
 m.from_location_type,
 m.order_number,
 m.order_line_id,
 'COMPANYNAME-E' company_name,
 'old' origin
 FROM `REDACTED_PROJECT.REDACTED_HOST.supplier_shipments` ss , UNNEST(moves) m 
 WHERE m.order_number IS NOT NULL 
 UNION ALL
 SELECT  
 ss.number,
 ss.state,
 ss.effective_date,
 ss.warehouse_name,
 ss.supplier_name,
 m.product_code,
 m.state moveState,
 m.quantity,
 m.uom_name,
 m.product_default_uom_name,
 m.from_location_type,
 m.order_number,
 m.order_line_id,
 'COMPANYNAME-F' company_name,
 'old' origin
 FROM `REDACTED_PROJECT.REDACTED_HOST.supplier_shipments` ss , UNNEST(moves) m 
 WHERE m.order_number IS NOT NULL 
 UNION ALL 
 SELECT  
 ss.number,
 ss.state,
 ss.effective_date,
 ss.warehouse_name,
 ss.supplier_name,
 m.product_code,
 m.state moveState,
 m.quantity,
 m.uom_name,
 m.product_default_uom_name,
 m.from_location_type,
 m.order_number,
 m.order_line_id,
 CASE WHEN company_id = 1 THEN 'COMPANYNAME-A'
      WHEN company_id = 2 THEN 'COMPANYNAME-B'
      WHEN company_id = 3 THEN 'COMPANYNAME-C'
      WHEN company_id = 4 THEN 'COMPANYNAME-D'
      WHEN company_id = 5 THEN 'COMPANYNAME-E'
      WHEN company_id = 6 THEN 'COMPANYNAME-F'
      ELSE CONCAT('ERR:[CTE=pr][CASE=OOB][value=company_id{',company_id,'}]')
END AS company_name,
 'new' origin
 FROM `REDACTED_PROJECT.REDACTED_HOST.supplier_shipments` ss , UNNEST(moves) m 
 WHERE m.order_number IS NOT NULL 
), 
# Final pr table
prf as(
  select * from pr WHERE moveState = 'done'
), 
# Calculate the amount of days from PO creation to Inventoried  
age as(
 SELECT 
  po.number ponum,
  po.product_code,
  po.company_name,
  INITCAP(TRIM(po.supplier_name)) supplier_name,
  prf.order_line_id, -- added debug
  po.id,
  prf.number ssnum,
  prf.origin,
  DATE_DIFF(prf.effective_date,po.purchase_date,DAY) age,
  DATE_DIFF(prf.effective_date,po.purchase_date,DAY)/30.5 ageMonth -- Changed from using MONTH delimiter to DAY/30.5 to preserve decimals, with MONTH everything under 30dys was 0
  FROM po
   JOIN prf ON (prf.product_code = po.product_code AND prf.order_number = po.number AND prf.order_line_id = po.id AND prf.company_name = po.company_name AND INITCAP(TRIM(prf.supplier_name)) = INITCAP(TRIM(po.supplier_name))) 
  WHERE DATE_DIFF(prf.effective_date,po.purchase_date,DAY) > 0
  ORDER BY product_code
), 
# Grab Just the product and company relation from age
ac AS(
  SELECT DISTINCT 
  company_name, 
  product_code
  from age
),
# Count The amount of occurences by product to guage accuracy, mainly used for LT & debugging 
cnt AS(
  SELECT 
  product_code,
  supplier_name,
  count(product_code) datapoints
  FROM age
  GROUP BY product_code, supplier_name
), 
# Grab the Static Lead Time existing in Fulfil
staticLT AS(
  SELECT 
  product_code,  
  INITCAP(TRIM(supplier_name)) supplier_name,
  lead_time_days,
  ROUND(SAFE_DIVIDE(lead_time_days,30.5),1) sltm,
  CASE WHEN company_id = 1 THEN 'COMPANYNAME-A'
     WHEN company_id = 2 THEN 'COMPANYNAME-B'
     WHEN company_id = 3 THEN 'COMPANYNAME-C'
     WHEN company_id = 4 THEN 'COMPANYNAME-D'
     WHEN company_id = 5 THEN 'COMPANYNAME-E'
     WHEN company_id = 6 THEN 'COMPANYNAME-F'
     ELSE 'ERR:CASE_OOB_[staticLT]'
 END AS company_name,
 FROM `REDACTED_PROJECT.REDACTED_HOST.product_suppliers` 
 WHERE lead_time_days IS NOT NULL
 ORDER BY supplier_name
), 
# Calculate min/max/average/standard deviation For Lead Time days/months
newLT AS(
  SELECT DISTINCT
  age.product_code,
  age.supplier_name,
  AVG(IFNULL(age.age,stl.lead_time_days))  averageLead,
  STDDEV_POP(IFNULL(age.age,stl.lead_time_days))  stdevpaLead,
  STDDEV(IFNULL(age.age,stl.lead_time_days)) stdevLead,
  MIN(IFNULL(age.age,stl.lead_time_days))  minLead,
  MAX(IFNULL(age.age,stl.lead_time_days))  maxLead,
  AVG(IFNULL(age.ageMonth,stl.sltm))  averageLeadMonth,
  STDDEV_POP(IFNULL(age.ageMonth,stl.sltm))  stdevpaLeadMonth,
  STDDEV(IFNULL(age.ageMonth,stl.sltm)) stdevLeadMonth,
  MIN(IFNULL(age.ageMonth,stl.sltm))  minLeadMonth,
  MAX(IFNULL(age.ageMonth,stl.sltm))  maxLeadMonth
  FROM age
  LEFT JOIN staticLT stl ON stl.product_code = age.product_code AND stl.supplier_name = age.supplier_name
  GROUP BY product_code, supplier_name
), 
# add called sales data to CTE
ltms AS(
 SELECT * FROM `REDACTED_PROJECT.REDACTED_HOST.spResultFinal`
), 
# add called stddev data from unpivotd sales data
stdev AS(
  SELECT * FROM `REDACTED_PROJECT.REDACTED_HOST.spRptResultUnpivot`
),
#Pull in Current (HQ) Inventory from snap 
i AS(
  SELECT 
  company_name,
  product product_code,
  productVariantName,
  warehouseName warehouse_name,
  warehouseCode warehouse_code,
  qtyOH,
  qtyAvail,
  qtyBuildable,
  active
  FROM `REDACTED_PROJECT.REDACTED_HOST.dailyProductSnap`
  WHERE dateRecorded = current_date()
  AND warehouseName LIKE '%HQ Warehouse' -- Excludes Amazon FBA Inventory 
  #AND company_name NOT LIKE '%(%)%' 
), 
# Add called exploded bom data
bom AS(
  SELECT * FROM `REDACTED_PROJECT.REDACTED_HOST.explodedBOM`
)
 # Pulls all active products and assigns type (purchase or production) 
, ap AS(
  SELECT 
  code product_code,
  variant_name,
  CASE WHEN EXISTS (SELECT output FROM bom WHERE bom.output = code) THEN 'production' 
       WHEN EXISTS (SELECT product_code FROM `REDACTED_PROJECT.REDACTED_HOST.product_suppliers` ps WHERE ps.product_code = product_code) THEN 'purchase'
       WHEN EXISTS (SELECT code FROM `REDACTED_PROJECT.REDACTED_HOST.product_suppliers` ps WHERE ps.code = product_code) THEN 'purchase'
  ELSE 'eyeBallIt'
  END as type 
  FROM `REDACTED_PROJECT.REDACTED_HOST.products`
  WHERE active = TRUE
)
# Adds Logic to Dynamically Pick LT with Greatest Data Points and Lead
, qq AS(
  SELECT 
  newLT.*, cnt.datapoints,
  row_number() OVER(PARTITION BY product_code ORDER BY datapoints DESC, averageLead DESC) rk
  FROM newLT
  INNER JOIN cnt USING (product_code,supplier_name)
  )
# Garbage way of finding company_name
,c as(
  SELECT product_code, company_name,
  row_number() OVER (partition by product_code order by cp desc) crk
  FROM(
  SELECT  product_code,
  CASE WHEN company_id = 1 THEN 'COMPANYNAME-A'
     WHEN company_id = 2 THEN 'COMPANYNAME-B'
     WHEN company_id = 3 THEN 'COMPANYNAME-C'
     WHEN company_id = 4 THEN 'COMPANYNAME-D'
     WHEN company_id = 5 THEN 'COMPANYNAME-E'
     WHEN company_id = 6 THEN 'COMPANYNAME-F'
     ELSE 'ERR:CASE_OOB_[c]'
   END AS company_name, 
  COUNT(product_code) cp  
  FROM `REDACTED_PROJECT.REDACTED_HOST.inventory_moves`
  GROUP BY product_code, company_name
  #WHERE company_name NOT LIKE '[0-9]%' AND state = 'done'
  )
)
# Grabs LT for input (MAX datapoint + max leadtime) will be used in place of missing output LT
,ilt AS(
  SELECT 
  output,
  input,
  qq.* EXCEPT(rk),
  ROW_NUMBER() OVER (PARTITION BY output ORDER BY datapoints DESC, averageLead DESC ) irk
  FROM bom
  INNER JOIN qq ON qq.product_code = input AND rk = 1
) 
# Base Query for final result.
# qtyOH & qtyAvail When these are Negative or NULL, they will appear as 0 (could fix by not getting data from dailySnapshot)
,ss AS(
 SELECT 
 ap.product_code,
 ap.variant_name,
 ap.type,
 IFNULL(qq.supplier_name,ilt.supplier_name) supplier_name,
 ltms.* EXCEPT(product_code, ts), -- The * Contains the Month Variables, Total & 90da
 stdev.DSD, --Monthly This will omit blanks & nulls which is fine for LT, but not Sales
 stdev.DSD_PA, -- Monthly Also use this one, we want to include, not exclude 0's
 stdev.average salesAvgMonth,
 COALESCE(qq.averageLead,ilt.averageLead,ilti.averageLead) averageLead,
 COALESCE(qq.stdevpaLead,ilt.stdevpaLead,ilti.stdevpaLead) SDPALT,
 COALESCE(qq.stdevLead,ilt.stdevLead,ilti.stdevLead) SDLT,
 COALESCE(qq.maxLead,ilt.maxLead,ilti.maxLead) maxLead,
 COALESCE(qq.minLead, ilt.minLead, ilti.minLead) minLead, 
 COALESCE(qq.averageLeadMonth,ilt.averageLeadMonth,ilti.averageLeadMonth) averageLeadMonth,
 COALESCE(qq.stdevpaLeadMonth,ilt.stdevpaLeadMonth,ilti.stdevpaLeadMonth) SDPALTMonth,
 COALESCE(qq.stdevLeadMonth,ilt.stdevLeadMonth,ilti.stdevLeadMonth) SDLTMonth,
 COALESCE(qq.maxLeadMonth,ilt.maxLeadMonth,ilt.maxLeadMonth) maxLeadMonth,
 COALESCE(qq.minLeadMonth, ilt.minLeadMonth,ilt.minLeadMonth) minLeadMonth,
 CASE WHEN i.warehouse_name IS NULL AND COALESCE(ac.company_name, i.company_name,c.company_name) = 'COMPANYNAME-B' THEN 'BBB HQ Warehouse'
      WHEN i.warehouse_name IS NULL AND COALESCE(ac.company_name, i.company_name,c.company_name) != 'COMPANYNAME-B' THEN 'HQ Warehouse'
      ELSE i.warehouse_name END AS warehouse_name, -- Both Case Statements will need updated if AMZ is Added
 CASE WHEN i.warehouse_code IS NULL AND COALESCE(ac.company_name, i.company_name,c.company_name) = 'COMPANYNAME-B' THEN 'BBB HQ'
      WHEN i.warehouse_code IS NULL AND COALESCE(ac.company_name, i.company_name,c.company_name) != 'COMPANYNAME-B' THEN 'WH'
      ELSE i.warehouse_code END AS warehouse_code,
 #i.warehouse_code warehouse_code_og,
 IFNULL(i.qtyOH,0) qtyOH,
 IFNULL(i.qtyAvail,0) qtyAvailable, 
 i.qtyBuildable, -- When Null Likely Not a Kit
 COALESCE(ac.company_name, i.company_name,c.company_name) company_name,
 CASE WHEN ltms.nda >= .5 THEN 'A' 
      WHEN ltms.nda >= .2 THEN 'B' 
      WHEN ltms.nda >= .1 THEN 'C'
      WHEN ltms.nda >   0 THEN 'D'
      ELSE 'E'
 END AS popCode
 FROM ap
 INNER JOIN ltms ON ltms.product_code = ap.product_code
 INNER JOIN stdev ON stdev.product_code = ap.product_code AND stdev.average != 0
 LEFT JOIN qq ON qq.product_code = ap.product_code AND qq.rk = 1
 LEFT JOIN ilt ON ilt.output = ap.product_code AND ilt.irk = 1 
 LEFT JOIN ilt ilti ON ilti.input = ap.product_code AND ilti.irk = 1
 LEFT JOIN i ON i.product_code = ap.product_code
 LEFT JOIN c ON c.product_code = ap.product_code AND c.crk = 1
 LEFT JOIN ac ON ac.product_code = ap.product_code
 WHERE ltms.tot IS NOT NULL AND COALESCE(qq.stdevLead,ilt.stdevLead,ilti.stdevLead) IS NOT NULL 
 ORDER BY company_name ASC, ap.product_code ASC
) 
# Add Method 5 safetyStock & reorderPoint - Final Report
SELECT DISTINCT
ss.*,
ROUND(SAFE_MULTIPLY(Z,SQRT((SAFE_MULTIPLY(averageLead,POWER(DSD_PA,2))+POWER(SAFE_MULTIPLY(salesAvgMonth, SDLTMonth),2))))) safetyStock, 
-- cap added - hardcode LT & second segma capped at 60day
ROUND(SAFE_MULTIPLY(Z,SQRT((SAFE_MULTIPLY(IF(averageLead BETWEEN 10 AND 30,averageLead,30.5),IF(POWER(DSD_PA,2)>nda*60,nda*60,POWER(DSD_PA,2)))+POWER(SAFE_MULTIPLY(salesAvgMonth, .22),2))))) safetyStock_mod, 
ROUND(SAFE_MULTIPLY(Z,SQRT((SAFE_MULTIPLY(averageLead,POWER(DSD_PA,2))+POWER(SAFE_MULTIPLY(salesAvgMonth, SDLTMonth),2))))+(salesAvgMonth/30.5)*averageLead) reorderPoint,
-- cap added - hardcode LT & second segma capped at 60day
ROUND(SAFE_MULTIPLY(Z,SQRT((SAFE_MULTIPLY(IF(averageLead BETWEEN 10 AND 30,averageLead,30.5),IF(POWER(DSD_PA,2)>nda*60,nda*60,POWER(DSD_PA,2)))+POWER(SAFE_MULTIPLY(salesAvgMonth, .22),2))))+(salesAvgMonth/30.5)*IF(averageLead BETWEEN 10 AND 30,averageLead,30.5)) reorderPoint_mod
FROM ss


###############################################################################################
## ** Nothing but more Validation, Spot Checking, Debugging and Embarrassment Beyond here ** ##
###############################################################################################

# Notes:
 # **Investigate: xxxxx** - why is this not on the report? po filter? age filter? ss filter?
 # ensure lead month calc has decimals, this also applies for min/max's of this column 




#
# .. queries for validating CTE data/calcs ..
 #SELECT * FROM qq WHERE product_code = 'xxx'                      -- From newLT picks LT Row to use 
 #SELECT * FROM ilt --WHERE ilt.output = 'xxx' OR ilt.input = 'xxx' -- LT Calcs for Inputs
 #SELECT * FROM c WHERE product_code = 'xxx' AND crk = 1     -- company_name Data 
 #SELECT * FROM newLT --WHERE product_code = 'xxx'                   -- Initial minMaxStdev LT calcs
 #SELECT * FROM age WHERE ponum = 'PO14'AND ssnum = 'xxx' --WHERE product_code = 'xxx'                    -- Checks Base Data for LT calcs Blended po & prf
 #SELECT * FROM prf WHERE product_code = 'xxx'                    -- Check Receipts
 #SELECT * FROM po --WHERE product_code IN(xxx,yyy,zzz)                     -- Check POs
 #SELECT * FROM staticLT WHERE product_code = 'xxx'                -- Check StaticLead
 #SELECT * FROM ac ORDER BY product_code                            -- Check company_name supercedes [c]
 #SELECT * FROM bom WHERE input = 'xxxx'
 
 
# 
/* sanity checking ..
bug as (
   select * from( select count(product_code) over (partition by product_code, supplier_name) sku_vendor_occurence, product_code, supplier_name, age.age, age.ponum, age.ssnum, age.order_line_id,age.id, age.origin,  from age)
  where product_code IN(	'2600b')
 order by product_code, supplier_name, ponum
 --SOLVED: White Spaces Exist in supplier_name use INITCAP(TRIM))
) 
*/
/*
 select newLT.*, IFNULL(cnt.datapoints,0) datapoints
 from newLT
 LEFT JOIN cnt USING (product_code,supplier_name) 
*/
# Safety Stock Formula May be Moved to GS 
/*
# Keeping so I know what not to do, I miss mySQL's syntax for POW()
# Nonworking SafetyStock Formula Graveyard r/mildlyInfuriating
 (Z * SQRT((averageLead/30.5)*POW(DSD,2))+POW((average*SDLT),2)) safetyStock
 (Z * SQRT(POW((ROUND((averageLead/30.5),2)*POW(dsd,2))+(avgMSO*stdevLead),2))) safetyStock,
 (Z * SQRT(POW((ROUND((averageLead/30.5),2)*POW(dsd,2))+(avgMSO*stdevLead),2)))+averageLead*((avgMSO)/365) reorderPoint
 Z * SQRT(POW((averageLeadMonth * POW(DSD_PA,2))+(salesAvgMonth * SDLTMonth),2)) safetyStock,
 (Z*SQRT(POWER((averageLeadMonth*POWER(DSD_PA,2))+(salesAvgMonth*SDLTMonth),2))) ssv2,
 Z * SQRT((POWER(averageLead*DSD_PA,2)+POWER(salesAvgMonth*SDLTMonth,2))) ammiRetarded,
 Z * SQRT(POWER(averageLead*DSD_PA,2)+(salesAvgMonth*POWER(SDLTMonth,2))) plsdude,
 Z * SQRT(POWER(averageLead*DSD_PA,2)+POWER((salesAvgMonth*SDLTMonth),2)) cmon,
 Z * SQRT(POWER(POWER(averageLead*DSD_PA,2)+(salesAvgMonth*SDLTMonth),2)) kms,
 SAFE_MULTIPLY(Z,SQRT(POWER((SAFE_MULTIPLY(averageLead,POWER(DSD_PA,2)))+(SAFE_MULTIPLY(salesAvgMonth, SDLTMonth)),2))) gross
 Z * SQRT(POW((averageLeadMonth * POW(DSD_PA,2))+(salesAvgMonth * SDLTMonth),2)) + (salesAvgMonth/30.5) * averageLead reOrderPoint,
 (Z*SQRT(POWER((averageLeadMonth*POWER(DSD_PA,2))+(salesAvgMonth*SDLTMonth),2)))+(salesAvgMonth/30.5)*ss.averageLead ropv2
 (Z * SQRT(((IFNULL(qq.averageLead,ilt.averageLead)/30.5)*POW(DSD,2))+POW((average*(IFNULL(qq.stdevLead,ilt.stdevLead))),2))) safetyStock, 
*/
# SOLVED 
 #/* somethings fucked with the stdev; doesnt match =stdevp() in gs on same data */
 # below works - converted to routine
 /*
 SELECT
 product_code,
 stddev(sales) DSD,
 stddev_pop(sales) DSD_PA,
 AVG(sales) average
 from(
 SELECT * FROM `REDACTED_PROJECT.REDACTED_HOST.spResult`
 UNPIVOT(sales FOR Month IN( October, September, August))
 WHERE tot > 0)
 GROUP BY product_code
 having product_code = 'xxxx'
*/
# *DEPRICATED* superceded by qq
/*
, dplt AS(
  SELECT
  product_code,
  MAX(averageLead) averageLead,
  FROM(
  SELECT 
  product_code,
  supplier_name,
  averageLead,
  max(datapoints)
  from newLT
  join cnt using (product_code,supplier_name)
  group by product_code, supplier_name, averageLead)
  GROUP BY product_code
)
*/
