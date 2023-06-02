-- merges staging table to production table
-- will be used in the connector script
merge gorgSurvey p
using (
	select 
	  * 
	from gorgSurveyStg 
	where load_date = current_date()
) s
on (
	p.id=s.id and 
	p.customer_id = s.customer_id
)
when matched and(
	(
		p.sent_datetime != s.sent_datetime
	) or(
		p.scored_datetime != s.scored_datetime
	) or(
		p.should_send_datetime != s.should_send_datetime
	)
) 
then
  update 
	  set
	    p.ticket_id = s.ticket_id,
	    p.sent_datetime = s.sent_datetime,
	    p.scored_datetime = s.scored_datetime,
	    p.meta = s.meta,
	    p.score = s.score,
	    p.customer_id = s.customer_id,
	    p.created_datetime = s.created_datetime,
	    p.uri = s.uri,
	    p.body_text = s.body_text,
	    p.should_send_datetime = s.should_send_datetime,
	    p.id = s.id
when not matched then
  insert(
	  ticket_id,
	  sent_datetime,
	  scored_datetime,
	  meta,
	  score,
	  customer_id,
	  created_datetime,
	  uri,
	  body_text,
	  should_send_datetime,
	  id,
	  load_date
)
values(
  s.ticket_id,
  s.sent_datetime,
  s.scored_datetime,
  s.meta,
  s.score,
  s.customer_id,
  s.created_datetime,
  s.uri,
  s.body_text,
  s.should_send_datetime,
  s.id,
  s.load_date
);
