-- This Function will be called when users toggle filter on dashboard in datastudio
-- converts dashboard filter output (string array) to bool array
CREATE
OR
REPLACE FUNCTION `PROJECT.HOST.fn_string_to_bool_array`(input_array ARRAY<string>)
RETURNS ARRAY<bool> AS(
(
       SELECT ARRAY
              (
                     SELECT CAST(x AS bool)
                     FROM UNNEST(input_array) x) ) );
