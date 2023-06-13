/* 
Deprecating Current Ticket Table
Drop existing table, replace it with working model.
Add neccessary ts columns. 
20230613 CD
*/
-- drop current version of table
drop table if exists manifest.gorgTicket;

-- promote dev to prod by renaming 
alter table manifest.pdtest3
rename to gorgTicket;

-- add load ts column to prod table
alter table manifest.gorgTicket
add column load_ts datetime;

-- set load ts default values
alter table manifest.gorgTicket
alter column load_ts set default current_datetime('America/New_York');

-- add mod ts column to prod table
alter table manifest.gorgTicket
add column mod_ts datetime;

-- set mod ts default values
alter table manifest.gorgTicket
alter column mod_ts set default null;

-- add load ts column to stg table
alter table manifest.gorgTicketStg
add column load_ts datetime;

-- set load ts default values
alter table manifest.gorgTicketStg
alter column load_ts set default current_datetime('America/New_York');
