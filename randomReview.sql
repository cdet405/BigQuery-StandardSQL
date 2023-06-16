-- fetch a single random review message
select 
  body_text 
from manifest.gorgSurvey
where score = 5 -- only consider 5 star reviews
and (
  body_text is not null 
  and body_text <> ""
)
and date(scored_datetime) >= current_date() - interval 90 day
order by
  rand() 
limit 1;
