-- searches for new category and assigns company_id
-- assuming naming convention is followed...

create or replace procedure `project.dataset.updateCat2Company`()

begin 

declare n int64;

set n = (
  select 
    count(category_name) 
  from `project.dataset.products` 
  where category_name not in(
    select 
      category_name 
    from `project.dataset.categorytocompany`
  )
);
-- exit criteria: if theres no update then exit
if n = 0 then return; end if;

insert into `project.dataset.categorytocompany`(
  category_name,
  company_id,
  company_name
)
with t as(
  select distinct
    category_name,
    case when category_name like '%sfv%' then 2 
         when category_name like '%hcf%' then 3
         when category_name like '%lrh%' then 5
         when category_name like 'sa%' then 6
         when category_name like 'dn%' then 4
         when category_name like '%dfs%' then 2
         when category_name like 'lh%' then 5
         when category_name like 'bb%' then 2
         when category_name like '%ikcin%' then 4
         else null end as company_id
  from `project.dataset.products` 
  where category_name not in(
    select 
      category_name 
    from `project.dataset.categorytocompany`
  )
)
select 
  category_name, 
  company_id, 
  case when company_id = 1 then 'companyName1'
       when company_id = 2 then 'companyName2'
       when company_id = 3 then 'companyName3'
       when company_id = 4 then 'companyName4'
       when company_id = 5 then 'companyName5'
       when company_id = 6 then 'companyName6'
       when company_id = 8 then 'companyName8' 
       else null end as company_name
from t;

end;
