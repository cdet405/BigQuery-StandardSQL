-- merge statement to be used for ticket pipeline
-- prod version 1.1 - 20230613CD
---------------------------------------------------
merge manifest.gorgTicket p 
using manifest.gorgTicketStg s 
on p.id = s.id 
when 
  matched 
    and(
      p.updated_datetime != s.updated_datetime
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
        p.spam = s.spam,
        p.opened_datetime = s.opened_datetime,
        p.last_received_message_datetime = s.last_received_message_datetime,
        p.last_message_datetime = s.last_message_datetime,
        p.updated_datetime = s.updated_datetime,
        p.closed_datetime = s.closed_datetime,
        p.snooze_datetime = s.snooze_datetime,
        p.trashed_datetime = s.trashed_datetime,
        p.integrations = s.integrations,
        p.messages_count = s.messages_count,
        p.mod_ts = current_datetime('America/New_York')
when 
  not matched 
    then 
      insert(
        id,
        uri,
        external_id,
        language,
        status,
        priority,
        channel,
        via,
        customer,
        assignee_user,
        assignee_team,
        subject,
        tags,
        is_unread,
        spam,
        created_datetime,
        opened_datetime,
        last_received_message_datetime,
        last_message_datetime,
        updated_datetime,
        closed_datetime,
        snooze_datetime,
        trashed_datetime,
        integrations,
        messages_count,
        load_ts,
        mod_ts,
        from_agent
      )
      values(
        s.id,
        s.uri,
        s.external_id,
        s.language,
        s.status,
        s.priority,
        s.channel,
        s.via,
        s.customer,
        s.assignee_user,
        s.assignee_team,
        s.subject,
        s.tags,
        s.is_unread,
        s.spam,
        s.created_datetime,
        s.opened_datetime,
        s.last_received_message_datetime,
        s.last_message_datetime,
        s.updated_datetime,
        s.closed_datetime,
        s.snooze_datetime,
        s.trashed_datetime,
        s.integrations,
        s.messages_count,
        s.load_ts,
        s.mod_ts,
        s.from_agent
      )
;
