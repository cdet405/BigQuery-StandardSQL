/* 
A BLESSING IN DISGUISE, THIS DOESNT WORK.
WORKING ON SOLUTION. 
Invalid value: Invalid schema update. Cannot add fields (field: string_field_0) at [47:1]
20230606CD
*/


-- phase one ticket ingest 
-- theres gotta be a better way
-- //TODO: figure out a better way to do this

-- commenting out not safe to run

/*
create or replace table manifest.gtt1(
  opened_datetime timestamp,
  priority string,
  subject string,	
  created_datetime timestamp,
  uri string,	
  assignee_user_lastname string,	
  assignee_user_id int64,	
  assignee_team string,	
  integrations json options(description="you either die a hero, or live long enough to become the villian"),	
  assignee_user_email string,	
  customer_firstname string,	
  last_received_message_datetime timestamp,	
  channel string,	
  snooze_datetime timestamp,	
  customer_lastname timestamp,	
  from_agent bool,	
  spam bool,	
  messages_count int64,	
  last_message_datetime timestamp,	
  closed_datetime timestamp,	
  id int64 not null,	
  updated_datetime timestamp,	
  customer_id int64,	
  customer_name string,	
  assignee_user_firstname string,	
  assignee_user string,	
  external_id int64,	
  is_unread bool,	
  trashed_datetime timestamp,	
  excerpt string,	
  assignee_user_name string,	
  tags json options(description="im sorry for this, im in my villian arc"),	
  language string,	
  status string,	
  customer_email string,	
  via string,
  load_ts timestamp default current_timestamp() options(description="ts inserted by user/script"),
  mod_ts timestamp default null options(description="ts row modifified (prob wont be used)")
)
options(description=("gtt-ph1-transform"))


*/
