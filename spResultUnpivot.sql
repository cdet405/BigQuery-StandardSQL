-- Unpivots With Dynamic Headers and Runs DS STDDEV Calcs - stores in table
BEGIN
DECLARE var_n0, var_n1, var_n2, var_n3, dt, ct, it, b, sql, f STRING;
SET var_n0 = FORMAT_DATE('%B', CURRENT_DATE());
SET var_n1 = FORMAT_DATE('%B',CURRENT_DATE() - INTERVAL 1 MONTH);
SET var_n2 = FORMAT_DATE('%B',CURRENT_DATE() - INTERVAL 2 MONTH);
SET var_n3 = FORMAT_DATE('%B',CURRENT_DATE() - INTERVAL 4 MONTH);
SET b = " ";
SET dt = " DROP TABLE IF EXISTS `REDACTED_PROJECT.REDACTED_HOST.spRptResultUnpivot`; ";
SET ct = " CREATE TABLE `REDACTED_PROJECT.REDACTED_HOST.spRptResultUnpivot` (product_code STRING, DSD FLOAT64, DSD_PA FLOAT64, average FLOAT64, ts DATE DEFAULT CURRENT_DATE()); ";
SET it = " INSERT INTO `REDACTED_PROJECT.REDACTED_HOST.spRptResultUnpivot` (product_code, DSD, DSD_PA, average) "; 
SET sql = CONCAT("SELECT product_code, STDDEV(sales) DSD, STDDEV_POP(sales) DSD_PA, AVG(sales) average FROM( SELECT * FROM `REDACTED_PROJECT.REDACTED_HOST.spResultFinal` UNPIVOT(sales FOR Month IN( ",var_n1,", ",var_n2," , ",var_n3," )) WHERE tot > 0) GROUP BY product_code;");
SET f = CONCAT(it,b,sql);
EXECUTE IMMEDIATE dt;
EXECUTE IMMEDIATE ct;
EXECUTE IMMEDIATE f;
END