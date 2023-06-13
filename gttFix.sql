-- regards pdtest3>gorgTicket | Hot Fix CD 20230613
-- backfill of historical data had a mismatch of datatypes for `from_agent`
-- all recent records are bool where as old data came through as 1,0 floats 
-- this fixes datatype issue blocking main merge from stg to prod


-- start fresh 
drop table if exists manifest.tmpgtt;

-- create working table 
create or replace table manifest.tmpgtt(
  id int64,
  from_agent_old float64,
  from_agent_new bool
);

-- insert current records & fix records
insert into manifest.tmpgtt
  (
    id,
    from_agent_old,
    from_agent_new
  )
select 
  id,
  from_agent as from_agent_old,
  if(from_agent>0,true,false) as from_agent_new
from manifest.gorgTicket;

-- wipe out records to avoid datatype conflict
update manifest.gorgTicket 
set from_agent = null
where true;

-- correct columns datatype
alter table manifest.gorgTicket
alter column from_agent
set data type bool; 

-- replace deleted records with copy
merge manifest.gorgTicket p  
using manigest.tmpgtt t 
on p.id = t.id
when matched then 
  update set
    p.from_agent = t.from_agent_new;

-- clean up
drop table manifest.tmpgtt;
