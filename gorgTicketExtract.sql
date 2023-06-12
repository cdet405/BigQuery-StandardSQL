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
  JSON_EXTRACT_SCALAR(customer, '$.id') AS customer_id,
  JSON_EXTRACT_SCALAR(customer, '$.email') AS customer_email,
  JSON_EXTRACT_SCALAR(customer, '$.name') AS customer_name,
  JSON_EXTRACT_SCALAR(customer, '$.firstname') AS customer_firstname,
  IF(JSON_EXTRACT(customer, '$.lastname')='""',NULL,JSON_EXTRACT_SCALAR(customer, '$.lastname')) AS customer_lastname,
  JSON_EXTRACT_SCALAR(assignee_user, '$.id') AS assignee_user_id,
  JSON_EXTRACT_SCALAR(assignee_user, '$.email') AS assignee_user_email,
  JSON_EXTRACT_SCALAR(assignee_user, '$.name') AS assignee_user_name,
  JSON_EXTRACT_SCALAR(assignee_user, '$.firstname') AS assignee_user_firstname,
  IF(JSON_EXTRACT(assignee_user, '$.lastname')='""',NULL,JSON_EXTRACT_SCALAR(assignee_user, '$.lastname')) AS assignee_user_lastname,
  JSON_EXTRACT_SCALAR(assignee_team, '$.id') AS assignee_team_id,
  JSON_EXTRACT_SCALAR(assignee_team, '$.name') AS assignee_team_name,
  ARRAY_AGG(integration_name) integration_name,
  ARRAY_AGG(integration_address) integration_address,
  ARRAY_AGG(tag_name) tag_names
FROM 
  manifest.pdtest3
  CROSS JOIN UNNEST([customer]) AS customer
  CROSS JOIN UNNEST([assignee_user]) as assignee_user
  CROSS JOIN UNNEST([assignee_team]) as assignee_team
  CROSS JOIN UNNEST(JSON_EXTRACT_ARRAY(tags, '$')) AS tag
  CROSS JOIN UNNEST([JSON_EXTRACT_SCALAR(tag, '$.name')]) AS tag_name
  CROSS JOIN UNNEST(JSON_EXTRACT_ARRAY(integrations, '$')) AS integration
  CROSS JOIN UNNEST([JSON_EXTRACT_SCALAR(integration, '$.name')]) AS integration_name
  CROSS JOIN UNNEST([JSON_EXTRACT_SCALAR(integration, '$.address')]) AS integration_address 
WHERE id=228852813
GROUP BY 
  1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27
