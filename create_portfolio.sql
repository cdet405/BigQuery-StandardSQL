-- create table to assign portfolio label.
-- label will be used as a filter in reports. 
-- may add additional columns in the future. 

CREATE OR REPLACE TABLE `progect.dataset.portfolio`(
  label STRING,
  company_name STRING
);
INSERT INTO `progect.dataset.portfolio`
(
  label, 
  company_name
)
VALUES
('A','companyv1'),
('A','companyc2'),
('A','companyn3'),
('B','companyh4'),
('B','companya5'),
('A','companycc6'),
('B','companyak7'),
('C','companysr8'),
('A','companyuw9'),
('Z','company3h10'),
('Z','company3ff11')
;
