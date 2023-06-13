-- formerly pdtest3
-- schema is the same for the stg table except mod_ts is dropped

CREATE TABLE manifest.gorgTicket
(
  id INT64,
  uri STRING,
  external_id STRING,
  language STRING,
  status STRING,
  priority STRING,
  channel STRING,
  via STRING,
  from_agent FLOAT64,
  customer STRING, -- json string
  assignee_user STRING, -- json string
  assignee_team STRING, -- json string
  subject STRING,
  tags STRING, -- json string
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
  integrations STRING, -- json string
  messages_count INT64,
  load_ts DATETIME DEFAULT current_datetime('America/New_York'),
  mod_ts DATETIME DEFAULT null -- this column doesnt exist in stg version
)
OPTIONS(
  expiration_timestamp=TIMESTAMP ""2033-06-09T18:06:19.364Z""
);
