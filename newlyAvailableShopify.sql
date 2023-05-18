-- returns products that are back in stock on shopify store
with s as(
  select * from `project.dataset.shopifyScrape`
  where runDate >= date_sub(current_date(), interval 1 DAY)
)
select s.*, x.vid from s
inner join(
  select *, from s 
  where available = false
) x on (x.vid=s.vid and x.site=s.site and x.runDate!=s.runDate)
where (s.runDate=current_date() AND s.available = true)
