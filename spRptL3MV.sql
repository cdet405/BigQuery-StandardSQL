-- Last 3 Months Product Velocity
BEGIN

DECLARE var_0, var_1, var_2, var_3 INT64;
DECLARE var_n0, var_n1, var_n2, var_n3, dt, dt2, ct, ct2, it, it2, b, sql, f, sql2, so, iso, bom, f2, dt3, ct3, it3, u, sql3, f3, uom, xb  STRING;
CALL manifest.spExplodeBOM(); -- Explodes BOM
-- Modified Intervals temporarily to remove bfcm volume, next 1-3-4,1-2-4 then back to normal 1-2-3
-- update monthly until nov isnt in past 3 full months. next year add nov22 >=90 days before nov23
SET var_3 = EXTRACT(MONTH FROM CURRENT_DATE() - INTERVAL 4 MONTH);
SET var_2 = EXTRACT(MONTH FROM CURRENT_DATE() - INTERVAL 2 MONTH);
SET var_1 = EXTRACT(MONTH FROM CURRENT_DATE() - INTERVAL 1 MONTH);
SET var_0 = EXTRACT(MONTH FROM CURRENT_DATE());
SET var_n0 = FORMAT_DATE('%B', CURRENT_DATE());
SET var_n1 = FORMAT_DATE('%B',CURRENT_DATE() - INTERVAL 1 MONTH);
SET var_n2 = FORMAT_DATE('%B',CURRENT_DATE() - INTERVAL 2 MONTH);
SET var_n3 = FORMAT_DATE('%B',CURRENT_DATE() - INTERVAL 4 MONTH);
SET dt =" DROP TABLE IF EXISTS `REDACTED_PROJECT.REDACTED_HOST.spResult`; ";
SET dt2 =" DROP TABLE IF EXISTS `REDACTED_PROJECT.REDACTED_HOST.spResultInput`; ";
SET dt3 =" DROP TABLE IF EXISTS `REDACTED_PROJECT.REDACTED_HOST.spResultFinal`; ";
SET ct =  CONCAT(" CREATE TABLE `REDACTED_PROJECT.REDACTED_HOST.spResult` (product_code STRING, ", var_n0, " FLOAT64 ,", var_n1, " FLOAT64 ,", var_n2, " FLOAT64 ,", var_n3, " FLOAT64, tot FLOAT64, nda FLOAT64, ts DATE DEFAULT CURRENT_DATE());" );
SET ct2 =  CONCAT(" CREATE TABLE `REDACTED_PROJECT.REDACTED_HOST.spResultInput` (input STRING, ", var_n0, " FLOAT64 ,", var_n1, " FLOAT64 ,", var_n2, " FLOAT64 ,", var_n3, " FLOAT64, tot FLOAT64, nda FLOAT64, ts DATE DEFAULT CURRENT_DATE());" );
SET ct3 = CONCAT("CREATE TABLE `REDACTED_PROJECT.REDACTED_HOST.spResultFinal` (product_code STRING,", var_n0,"  FLOAT64,", var_n1," FLOAT64,", var_n2," FLOAT64,", var_n3 ," FLOAT64, tot FLOAT64, nda FLOAT64, ts DATE DEFAULT CURRENT_DATE());");
SET it = CONCAT(" INSERT INTO `REDACTED_PROJECT.REDACTED_HOST.spResult` (product_code, ",var_n0,", ",var_n1,", ",var_n2," ,",var_n3,", tot, nda) ");
SET it2 = CONCAT(" INSERT INTO `REDACTED_PROJECT.REDACTED_HOST.spResultInput` (input, ",var_n0,", ",var_n1,", ",var_n2," ,",var_n3,", tot, nda) ");
SET it3 = CONCAT(" INSERT INTO `REDACTED_PROJECT.REDACTED_HOST.spResultFinal` (product_code, ",var_n0,", ",var_n1,", ",var_n2," ,",var_n3,", tot, nda) ");
SET b = " ";
SET so = " (select product_code, quantity as tot, extract(month from order_date) as month, order_date from `REDACTED_PROJECT.REDACTED_HOST.v_salesOrders` WHERE order_date >= current_date() - interval 6 MONTH ) ";

-- grabs all uom for inputs
# Depricated uom to xb
#SET uom = " LEFT JOIN (SELECT code, default_uom_name d_uom, purchase_uom_name p_uom, sale_uom_name s_uom FROM `REDACTED_PROJECT.REDACTED_HOST.products` WHERE active = true ) iu ON iu.code = i.product_code "; 

-- Added uom to bom
# Depricated bom to xb
#SET bom = CONCAT(" LEFT JOIN (SELECT o.product_code output, i.product_code input, i.quantity qtyRequired, i.input_uom_name bom_uom, iu.d_uom, iu.p_uom, iu.s_uom, b.active, b.is_built_on_the_fly botf FROM `REDACTED_PROJECT.REDACTED_HOST.production_boms` b LEFT JOIN UNNEST(inputs) i LEFT JOIN UNNEST(outputs) o ",uom,") bom ON bom.output = product_code  ");

-- corrects input uoms to purchase amount
-- function requires grouping of x & y for n
# Depricated SS to xb
#SET iso = CONCAT("(SELECT product_code, input, qtyRequired, month, SUM(tot) * manifest.convert_uom(qtyRequired,bom_uom,d_uom) as itot, order_date FROM ",so,bom," GROUP BY product_code, input, qtyRequired, month, bom_uom,d_uom,p_uom, s_uom, order_date) ");

# og iso: before uom logic added 
#SET iso = CONCAT("(SELECT product_code, input, qtyRequired, month, SUM(tot) * qtyRequired as itot, order_date FROM ",so,bom," GROUP BY product_code, input, qtyRequired, month, order_date) ");
SET xb = FORMAT(
"""
(SELECT 
  product_code,
  input, 
  quantity, 
  month, 
  SUM(tot) * manifest.convert_uom(quantity,UoM,d_uom) as itot, 
  order_date 
  FROM (
    SELECT 
    product_code, 
    quantity as tot, 
    EXTRACT(month FROM order_date) as month, 
    order_date 
    FROM `REDACTED_PROJECT.REDACTED_HOST.v_salesOrders` 
    WHERE order_date >= CURRENT_DATE() - INTERVAL 6 MONTH
    )
  LEFT JOIN(
    SELECT
    boom.*,
    iu.d_uom,
    iu.p_uom,
    iu.s_uom,
    iu.w_uom
    FROM `REDACTED_PROJECT.REDACTED_HOST.explodedBOM` boom
    LEFT JOIN(
      SELECT 
      code, 
      default_uom_name d_uom, 
      purchase_uom_name p_uom, 
      sale_uom_name s_uom,
      weight_uom_name w_uom  
      FROM `REDACTED_PROJECT.REDACTED_HOST.products` 
      WHERE active = true 
      ) iu ON iu.code = boom.input
    WHERE topSkuBotF = true
  ) xx ON xx.topSku = product_code
GROUP BY product_code, input, quantity, month, UoM, d_uom, p_uom, s_uom, order_date)
"""
);

SET sql2 = CONCAT(" SELECT input,SUM(CASE WHEN month =", var_0," THEN itot ELSE 0 END ) ",var_n0," , SUM(CASE WHEN month = ",var_1," THEN itot ELSE 0 END ) ", var_n1,",SUM(CASE WHEN month =",var_2," THEN itot ELSE 0 END ) ",var_n2, ", SUM(CASE WHEN month = ",var_3," THEN itot ELSE 0 END ) ",var_n3,", (SUM(CASE WHEN month =", var_0," THEN itot ELSE 0 END ) + SUM(CASE WHEN month = ",var_1," THEN itot ELSE 0 END )+ SUM(CASE WHEN month =",var_2," THEN itot ELSE 0 END ) + SUM(CASE WHEN month = ",var_3," THEN itot ELSE 0 END )) tot, SUM(CASE WHEN order_date >= CURRENT_DATE() - INTERVAL 90 DAY THEN itot ELSE 0 END) as nda FROM ",xb," x WHERE input IS NOT NULL  GROUP BY input HAVING tot > 0 ORDER BY tot DESC;");


SET sql = CONCAT(" SELECT product_code,SUM(CASE WHEN month =", var_0," THEN tot ELSE 0 END ) ",var_n0," , SUM(CASE WHEN month = ",var_1," THEN tot ELSE 0 END ) ", var_n1,",SUM(CASE WHEN month =",var_2," THEN tot ELSE 0 END ) ",var_n2, ", SUM(CASE WHEN month = ",var_3," THEN tot ELSE 0 END ) ",var_n3,", (SUM(CASE WHEN month =", var_0," THEN tot ELSE 0 END ) + SUM(CASE WHEN month = ",var_1," THEN tot ELSE 0 END )+ SUM(CASE WHEN month =",var_2," THEN tot ELSE 0 END ) + SUM(CASE WHEN month = ",var_3," THEN tot ELSE 0 END )) tot, SUM(CASE WHEN order_date >= CURRENT_DATE() - INTERVAL 90 DAY THEN tot ELSE 0 END) as nda FROM ",so," x  GROUP BY product_code HAVING tot > 0 AND product_code IS NOT NULL ORDER BY tot DESC;");

SET u = "( SELECT * EXCEPT(ts) FROM `REDACTED_PROJECT.REDACTED_HOST.spResultInput` UNION ALL SELECT * EXCEPT(ts) FROM `REDACTED_PROJECT.REDACTED_HOST.spResult` )" ;

SET sql3 = CONCAT("SELECT input product_code, SUM(",var_n0,") ",var_n0,",  SUM(",var_n1,") ",var_n1,", SUM(",var_n2,") ",var_n2,", SUM(",var_n3,") ",var_n3,", SUM(tot) l3mt, SUM(nda)/90 nda  FROM ",u,"  GROUP BY product_code;");


SET f = CONCAT(it,b,sql);
SET f2 = CONCAT(it2,b,sql2);
SET f3 = CONCAT(it3,b,sql3);

EXECUTE IMMEDIATE dt;
EXECUTE IMMEDIATE ct;
EXECUTE IMMEDIATE f;
EXECUTE IMMEDIATE dt2;
EXECUTE IMMEDIATE ct2;
EXECUTE IMMEDIATE f2;
EXECUTE IMMEDIATE dt3;
EXECUTE IMMEDIATE ct3;
EXECUTE IMMEDIATE f3;

CALL manifest.spResultUnpivot(); -- Translates Execution Results for main dor STDEV Calc
END