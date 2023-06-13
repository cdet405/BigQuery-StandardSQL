-- formerly pdtest3
-- updated from gttFix.sql
-- now 1:1 with stg

CREATE TABLE `chaddata-359115.manifest.gorgTicket`
(
  id INT64,
  uri STRING,
  external_id STRING,
  language STRING,
  status STRING,
  priority STRING,
  channel STRING,
  via STRING,
  customer STRING,
  assignee_user STRING,
  assignee_team STRING,
  subject STRING,
  tags STRING,
  is_unread BOOL,
  spam BOOL,
  created_datetime TIMESTAMP,
  opened_datetime TIMESTAMP,
  last_received_message_datetime TIMESTAMP,
  last_message_datetime TIMESTAMP,
  updated_datetime TIMESTAMP,
  closed_datetime TIMESTAMP,
  snooze_datetime STRING,
  trashed_datetime TIMESTAMP,
  integrations STRING,
  messages_count INT64,
  load_ts DATETIME DEFAULT current_datetime('America/New_York'),
  mod_ts DATETIME DEFAULT null,
  from_agent BOOL
)
OPTIONS(
  expiration_timestamp=TIMESTAMP ""2033-06-09T18:06:19.364Z""
);
