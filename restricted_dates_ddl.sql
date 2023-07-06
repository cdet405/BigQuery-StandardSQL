-- reference table for fn_no_weekends()
-- currently holds next 3 years (may be missing unannounced nonworking days)
create table manifest.restricted_dates(
  name string options(description='Name/Reason of Holiday/Nonworking Day'),
  date date options(description='holiday/nonworking date to override'),
  day string options(description='holidays day of week'),
  override_date date options(description='new date to resume calc'),
  override_day string options(description='new day of week'),
  mod_ts datetime options(description='date modified est')
) options(description='referenced by fn_no_weekends() for ship time report');
insert into manifest.restricted_dates(
  name,
  date,
  day,
  override_date,
  override_day,
  mod_ts
)
VALUES
('New Years','2023-01-01','Sunday','2023-01-03','Tuesday',current_datetime('America/New_York')),
('Observed New Years','2023-01-02','Monday','2023-01-04','Wednesday',current_datetime('America/New_York')),
('Good Friday','2023-04-07','Friday','2023-04-10','Monday',current_datetime('America/New_York')),
('Memorial Day','2023-05-29','Monday','2023-05-31','Wednesday',current_datetime('America/New_York')),
('Independence Day','2023-07-04','Tuesday','2023-07-06','Thursday',current_datetime('America/New_York')),
('Labor Day','2023-09-04','Monday','2023-09-06','Wednesday',current_datetime('America/New_York')),
('Thanksgiving','2023-11-23','Thursday','2023-11-24','Friday',current_datetime('America/New_York')),
('Christmas Eve','2023-12-24','Sunday','2023-12-26','Tuesday',current_datetime('America/New_York')),
('Christmas','2023-12-25','Monday','2023-12-27','Wednesday',current_datetime('America/New_York')),
('New Years','2024-01-01','Monday','2024-01-03','Wednesday',current_datetime('America/New_York')),
('Observed New Years','2024-01-02','Tuesday','2024-01-03','Wednesday',current_datetime('America/New_York')),
('Good Friday','2024-03-29','Friday','2024-04-01','Monday',current_datetime('America/New_York')),
('Memorial Day','2024-05-27','Monday','2024-05-28','Tuesday',current_datetime('America/New_York')),
('Independence Day','2024-07-04','Thursday','2024-07-05','Friday',current_datetime('America/New_York')),
('Labor Day','2024-09-02','Monday','2024-09-03','Tuesday',current_datetime('America/New_York')),
('Thanksgiving','2024-11-28','Thursday','2024-11-29','Friday',current_datetime('America/New_York')),
('Christmas Eve','2024-12-24','Tuesday','2024-12-26','Thursday',current_datetime('America/New_York')),
('Christmas','2024-12-25','Wednesday','2024-12-27','Friday',current_datetime('America/New_York')),
('New Years','2025-01-01','Wednesday','2025-01-03','Friday',current_datetime('America/New_York')),
('Observed New Years','2025-01-02','Thursday','2025-01-03','Friday',current_datetime('America/New_York')),
('Good Friday','2025-04-18','Friday','2025-04-21','Monday',current_datetime('America/New_York')),
('Memorial Day','2025-05-26','Monday','2025-05-28','Wednesday',current_datetime('America/New_York')),
('Independence Day','2025-07-04','Friday','2025-07-07','Monday',current_datetime('America/New_York')),
('Labor Day','2025-09-01','Monday','2025-09-03','Wednesday',current_datetime('America/New_York')),
('Thanksgiving','2025-11-27','Thursday','2025-11-28','Friday',current_datetime('America/New_York')),
('Christmas Eve','2025-12-24','Wednesday','2025-12-29','Monday',current_datetime('America/New_York')),
('Christmas','2025-12-25','Thursday','2025-12-30','Tuesday',current_datetime('America/New_York'))
;
