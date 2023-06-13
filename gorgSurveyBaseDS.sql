-- to replace gorgSurveyKPI.sql as datastudio source
with s as(
  select 
    s.ticket_id,
    s.customer_id,
    s.id,
    s.scored_datetime,
    s.score
  from manifest.gorgSurvey s
  where s.score is not null
),
t as (
  select 
    t.id ticket_id,
    cast(json_extract_scalar(customer, '$.id') as int64) customer_id,
    json_extract_scalar(customer, '$.name') customer_name,
    json_extract_scalar(assignee_user, '$.firstname') assignee_user_firstname,
    json_extract_scalar(integrations, '$[0].address') integrations_address,
  from manifest.gorgTicket t
  cross join unnest([customer]) AS customer
  cross join unnest([assignee_user]) as assignee_user
  cross join unnest([integrations]) as integrations
)
select 
  id,
  ticket_id,
  date(scored_datetime) score_date,
  customer_name,
  assignee_user_firstname,
  regexp_extract(integrations_address, r'@(.+?)\.') integration,
  score
from s
inner join t using(ticket_id,customer_id)
order by 
  3 desc;
