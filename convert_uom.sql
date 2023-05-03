CREATE OR REPLACE FUNCTION `REDACTED_PROJECT.REDACTED_HOST.convert_uom`(value FLOAT64, from_unit STRING, to_unit STRING) RETURNS FLOAT64 AS (
-- Conversion logic, covers all current scenarios 
-- Else Covers cases when to_unit != 'Unit' AND from_unit = 'Unit'
-- These to_units are the following 'Cup', 'Square yard', 'Yard'
    CASE WHEN to_unit      IS NULL                            THEN  value
         WHEN from_unit    IS NULL                            THEN  value
         WHEN from_unit = 'Unit'                              THEN  value
         WHEN from_unit = to_unit                             THEN  value
         WHEN from_unit = 'Ounce'    AND to_unit = 'Gram'     THEN  value * 28.35
         WHEN from_unit = 'Ounce'    AND to_unit = 'Pound'    THEN  value * .0625
         WHEN from_unit = 'Ounce'    AND to_unit = 'Kilogram' THEN  value * .0283495
         WHEN from_unit = 'Kilogram' AND to_unit = 'Pound'    THEN  value * 2.20462
         WHEN from_unit = 'Kilogram' AND to_unit = 'Ounce'    THEN  value * 35.274
         WHEN from_unit = 'Kilogram' AND to_unit = 'Gram'     THEN  value * 1000
         WHEN from_unit = 'Gram'     AND to_unit = 'Pound'    THEN  value * .00220462
         WHEN from_unit = 'Gram'     AND to_unit = 'Ounce'    THEN  value * 0.035274
         WHEN from_unit = 'Gram'     AND to_unit = 'Kilogram' THEN  value * 0.001
         WHEN from_unit = 'Pound'    AND to_unit = 'Gram'     THEN  value * 453.592
         WHEN from_unit = 'Pound'    AND to_unit = 'Ounce'    THEN  value * 16
         WHEN from_unit = 'Pound'    AND to_unit = 'Kilogram' THEN  value * 0.453592
         WHEN from_unit = 'Yard'     AND to_unit = 'Meter'    THEN  value * 0.9144
         WHEN from_unit = 'Meter'    AND to_unit = 'Yard'     THEN  value * 1.09361
         WHEN from_unit = 'Cup'      AND to_unit = 'Gallon'   THEN  value * 0.625
         WHEN from_unit = 'Gallon'   AND to_unit = 'Cup'      THEN  value * 16
         ELSE value -- changed from ELSE NULL to not completely miss qty if OOB
     END
);
