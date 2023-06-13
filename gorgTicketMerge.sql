-- merge statement to be used for ticket pipeline
-- dev version 1 - for testing + concept 23613CD
---------------------------------------------------
merge manifest.pdtest3 p -- //todo: update table names to prod & stg
using manifest.pdtest2 s -- //todo: update table names to prod & stg
on p.id = s.id 
when 
  matched 
    and(
      p.updated_datetime != s.updated_datetime -- //todo: this should be the only column needed for update criteria (nned to verify)
    ) 
  then 
    update
      set 
        p.external_id = s.external_id,
        p.language = s.language,
        p.status = s.status,
        p.priority = s.priority,
        p.channel = s.channel,
        p.from_agent = s.from_agent,
        p.customer = s.customer,
        p.assignee_user = s.assignee_user,
        p.assignee_team = s.assignee_team,
        p.subject = s.subject,
        p.tags = s.tags,
        p.is_unread = s.is_unread,
        p.opened_datetime = s.opened_datetime,
        p.last_received_message_datetime = s.last_received_message_datetime,
        p.last_message_datetime = s.last_message_datetime,
        p.updated_datetime = s.updated_datetime,
        p.closed_datetime = s.closed_datetime,
        p.snooze_datetime = s.snooze_datetime,
        p.trashed_datetime = s.trashed_datetime,
        p.integrations = s.integrations,
        p.messages_count = s.messages_count
        -- ,p.mod_ts = current_date() -- //todo: add mod_ts column to prod table & uncomment 
when 
  not matched 
    then 
      insert row
      -- //todo: add load_ts to prod/stg table with default value of current_date()
