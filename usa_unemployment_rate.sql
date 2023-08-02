-- base data for sales comparison 
-- 2023-08-02 cd
-- Assets
-- gs1WrdZl2MoksZd_dthquODf1DTu3IYaBCL83UHeoB0He8CMD
-- https://www.statista.com/statistics/273909/seasonally-adjusted-monthly-unemployment-rate-in-the-us/

create table manifest.unemploymentRate(
  date_frame date,
  usa_unemployment_rate float64,
  ts datetime default current_datetime('America/New_York') 
);

insert into manifest.unemploymentRate(
  date_frame,
  usa_unemployment_rate
)
values
('2023-06-01',0.036),
('2023-05-01',0.037),
('2023-04-01',0.034),
('2023-03-01',0.035),
('2023-02-01',0.036),
('2023-01-01',0.034),
('2022-12-01',0.035),
('2022-11-01',0.036),
('2022-10-01',0.037),
('2022-09-01',0.035),
('2022-08-01',0.037),
('2022-07-01',0.035),
('2022-06-01',0.036),
('2022-05-01',0.036),
('2022-04-01',0.036),
('2022-03-01',0.036),
('2022-02-01',0.038),
('2022-01-01',0.04),
('2021-12-01',0.039),
('2021-11-01',0.042),
('2021-10-01',0.046),
('2021-09-01',0.048),
('2021-08-01',0.052),
('2021-07-01',0.054),
('2021-06-01',0.059)
;
