-- extract ticket info from json table cols
SELECT 
  id,
  created_datetime,
  opened_datetime,
  updated_datetime,
  last_received_message_datetime,
  last_message_datetime,
  closed_datetime,
  status,
  channel,
  via,
  from_agent,
  is_unread,
  spam,
  messages_count,
  subject,
  JSON_EXTRACT(customer, '$.id') AS customer_id,
  JSON_EXTRACT(customer, '$.email') AS customer_email,
  JSON_EXTRACT(customer, '$.name') AS customer_name,
  JSON_EXTRACT(customer, '$.firstname') AS customer_firstname,
  JSON_EXTRACT(customer, '$.lastname') AS customer_lastname,
  JSON_EXTRACT(assignee_user, '$.id') AS assignee_user_id,
  JSON_EXTRACT(assignee_user, '$.email') AS assignee_user_email,
  JSON_EXTRACT(assignee_user, '$.name') AS assignee_user_name,
  JSON_EXTRACT(assignee_user, '$.firstname') AS assignee_user_firstname,
  JSON_EXTRACT(assignee_user, '$.lastname') AS assignee_user_lastname,
  JSON_EXTRACT(assignee_team, '$.id') AS assignee_team_id,
  JSON_EXTRACT(assignee_team, '$.name') AS assignee_team_name,
  JSON_EXTRACT_SCALAR(integrations, '$[0].name') AS integrations_name,
  JSON_EXTRACT_SCALAR(integrations, '$[0].type') AS integrations_type,
  JSON_EXTRACT_SCALAR(tags, '$[0].name') AS tags_name,
  JSON_EXTRACT_SCALAR(integrations, '$[1].name') AS integrations_name2,
  JSON_EXTRACT_SCALAR(integrations, '$[1].type') AS integrations_type2,
  JSON_EXTRACT_SCALAR(tags, '$[1].name') AS tags_name2
FROM 
  manifest.pdtest3 
  CROSS JOIN UNNEST([customer]) AS customer
  CROSS JOIN UNNEST([assignee_user]) as assignee_user
  CROSS JOIN UNNEST([assignee_team]) as assignee_team
  CROSS JOIN UNNEST([tags]) as tags
  CROSS JOIN UNNEST([integrations]) as integrations
WHERE id=228852813
