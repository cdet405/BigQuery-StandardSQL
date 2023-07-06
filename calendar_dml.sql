-- Fix Schema && Add Assets
alter table manifest.calendar
add column mod_ts datetime;
alter table manifest.calendar
alter column mod_ts 
set default current_datetime(
  'America/New_York'
);
update manifest.calendar
set mod_ts = current_datetime(
  'America/New_York'
  )
where mod_ts is null;
merge manifest.calendar p
using (
  select
    dates,
    format_date(
      '%A',
      date(dates)
    ) day
  from manifest.calendar
) s on p.dates = s.dates
when matched
  then update
    set 
      p.day = s.day,
      p.mod_ts = current_datetime(
        'America/New_York'
      );
update manifest.calendar
  set 
    restricted = true,
    mod_ts = current_datetime(
  'America/New_York'
  )
where day like 'S%day';
merge manifest.calendar p
using manifest.restricted_dates s
on p.dates = s.date
when matched
  then update
    set 
      p.holiday = s.name,
      p.resume_date = s.override_date,
      p.resume_day = s.override_day,
      p.restricted = true,
      p.mod_ts = current_datetime(
        'America/New_York'
      );
