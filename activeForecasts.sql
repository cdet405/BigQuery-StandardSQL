-- fetch all active forecasts in erp
select 
  current_datetime('America/New_York') runDate,
  name,
  state,
  start_date,
  end_date,
  create_user_name,
  write_user_name,
  warehouse_name,
  l.*
from `project.dataset.inventory_forecasts`
,unnest(lines) l
where state = 'confirmed'
  and current_date() between @STARTDATE and @ENDDATE
;
