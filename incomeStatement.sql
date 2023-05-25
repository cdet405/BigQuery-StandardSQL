------------------------------------------
# ** 20230525_CD  P & L  version 1.13 ** #
------------------------------------------
# version 2  query clean up  in progress #
------------------------------------------
-- fetch all po cost lines
with poc as(
  select
    company_id,
    company_name,
    purchase_date,
    supplier_name,
    number po_num,
    po.state po_state,
    l.id lid,
    l.product_code,
    l.product_variant_name,
    l.description line_description,
    l.quantity,
    l.amount,
    l.unit_price,
    l.uom_name,
    l.line_type
  from `project.data.purchase_orders` po
  ,unnest(lines) l
  where l.line_type='purchase'
),
-- fetch account invoice lines related to po lines
ai as(
  select
    invoice_id,
    invoice_number,
    invoice_date,
    invoice_type,
    i.state invoice_state,
    i.currency invoice_currency,
    l.type line_type,
    l.product_code,
    l.product_name,
    l.quantity,
    l.unit_price,
    l.purchase_line_id,
    company_id,
    company_name
  from `project.data.account_invoices` i
  ,unnest(lines) l 
  where l.type='sale' 
  and invoice_type='in' 
  and l.purchase_line_id is not null
),
-- fetch product default uom & loaded costs
p as(
  select 
    code,
    category_name,
    purchase_uom_name p_uom,
    default_uom_name d_uom,
    sale_uom_name s_uom,
    active,
    c.cost,
    c.costing_method method,
    c.company_name,
    c.company_id,
    c.currency_code
  from `project.data.products`
   left join unnest(costs) c 
   --where  c.costing_method != 'fixed'
),
-- piv p to retain all company variations
piv as(
  select 
    * except(
      _1,
      _2,
      _3,
      _4,
      _5,
      _6
    ),
    ifnull(_1,0) c1,
    ifnull(_2,0) c2,
    ifnull(_3,0) c3,
    ifnull(_4,0) c4,
    ifnull(_5,0) c5,
    ifnull(_6,0) c6
  from(
    select 
      * 
    from(
      select 
        code, 
        active,
        p_uom,
        d_uom,
        s_uom, 
        cost, 
        company_id 
      from p
    )
    pivot(
      any_value(
        cost
      ) for company_id in(
        1,
        2,
        3,
        4,
        5,
        6
      )
    )
  )
order by code
), 
-- unpiv dataset to make it conditionally joinable
unpiv as(
  select 
    * 
  from piv 
  unpivot(
    cost 
    for company_id in(
      c1,
      c2,
      c3,
      c4,
      c5,
      c6
    )
  )
),
-- fix company_id aliases
funpiv as(
  select 
    * except(company_id), 
    cast(
      right(
        company_id,
        1
      )
     as int64
    ) as company_id 
  from unpiv 
),
-- clean up existing cost dataset
pc as(
  select
    company_id,
    code,
    cost
  from p
  where (
    active=true 
    and cost > 0
  )
),
-- resolve company_ids
cc as(
  select
   distinct
    code,
    category_name,
    ifnull(
      ii.company_id,
      c2c.company_id
    ) company_id
  from p
  left join(
    select 
     distinct 
      product_code, 
      company_id 
    from ai
  ) ii on ii.product_code=p.code
  left join `project.data.categorytocompany` c2c using (category_name)
),
-- bring in beachys standard cost 
-- ** if value is not at d_uom calc will be off 
-- *//TODO: ensure this dataset is only in d_uom*
-- this cost takes 2nd priority and will not be used when avgCost can be calc'd
db as(
  select
    company_id,
    code,
    beach_cost_price
  from `project.data.cogs`
  where beach_cost_price > 0
),
-- po to default conversion
-- conversion used outside of boms (aligns purchase/invoice uom with inventory uom)
d AS(
select 
  poc.*,
  p.d_uom,
  data.convert_uom(1,uom_name,d_uom) conversion
from poc  
inner join p on p.code=poc.product_code
),
-- po to invoice calc prep for avg
ip as(
  select 
    ai.company_id,
    ai.invoice_id,
    ai.invoice_date,
    ai.quantity invoice_qty,
    ai.unit_price invoice_unit_price,
    ai.product_code,
    d.uom_name line_uom,
    d.d_uom,
    d.conversion,
    safe_divide(
      ai.unit_price,
      d.conversion
    ) d_unit_price,
    d.po_num
  from ai 
  inner join d on d.lid=ai.purchase_line_id
),
-- avg cost
ac as(
  select
    company_id,
    product_code,
    d_uom,
    avg(d_unit_price) avgCost
  from ip
  group by company_id, product_code,d_uom
),
-- merged avg cost dataset for coalesce
mac as(
  select 
   distinct
    fp.company_id,
    fp.code,
    ac.avgCost, -- priority 1 in coalesce
    db.beach_cost_price bcost, -- priority 2 in coalesce
    fp.cost ff_cost, -- priority 3 in coalesce
    fp.d_uom
  from funpiv fp
  left join ac on (
    ac.product_code=fp.code 
    and ac.company_id=fp.company_id
  )
  left join db on (
    db.code=fp.code 
    and db.company_id=fp.company_id
  )
),
-- bom_id to output key
obi as(
  select 
    b.id bom_id, 
    o.product_code output,
    o.output_uom_name 
  from  `project.data.production_boms` b
  ,unnest(outputs) o
),
-- bom inputs avg cost conversion
bi as(
  select 
    b.id bom_id,
    i.product_code input,
    i.quantity,
    i.input_uom_name,
    cc.company_id,
    mac.d_uom,
    safe_multiply(
      data.convert_uom(
        i.quantity,
        i.input_uom_name,
        mac.d_uom
      ),
      coalesce(
        mac.avgCost, -- priority 1 value
        mac.bcost,  --  priority 2 value
        mac.ff_cost -- priority 3 value
      )
    ) icost,
    mac.avgCost,
    mac.bcost,
    mac.ff_cost
  from `project.data.production_boms` b
  ,unnest(inputs) i
  left join cc on cc.code=i.product_code
  left join mac on (
    mac.code=i.product_code 
    and mac.company_id=cc.company_id
  )
  where active=true
  order by 
    bom_id, 
    input
),
-- *reminder priority2 cost is static and not index'd to d_uom. risk of miscalc*
-- complete avg bom cost with data integrity score: score = % of bom child data accounted for.
-- if score < 1 avgBomCost is under valued. orphans=count of sku per bom missing in calc
bc as(
  select 
    bom_id, 
    round(
      sum(
        icost
      ),
     2
    ) bomCost, 
    count(bom_id) cntChild, 
    countif(
      ifnull(
        icost,
        0
      )
     =0
    ) cntOrphanChild,  
    safe_divide(
      countif(
        ifnull(
          icost,
          0
        )
       =0
      ), 
      count(bom_id)
    ) integrity,
    concat(
      'https://subdomain.domain.tld/client/#/model/production.bom/',
      bom_id,
      '?views=%5B%5B1072,%22tree%22%5D,%5B1073,%22form%22%5D%5D&context=%7B%22active_test%22:false%7D'
    ) link
  from bi 
  group by bom_id 
  order by bom_id
),
-- output sku cost
oc as(
  select
    obi.bom_id,
    obi.output,
    obi.output_uom_name,
    bc.* except(bom_id)
  from obi
  left join bc using (bom_id)
),
-- final cost result
cost as(
  select
    mac.*,
    oc.bomCost,
    oc.integrity,
    cc.company_id key_id,
    round(
      coalesce(
        oc.bomCost,
        mac.avgCost,
        mac.bcost,
        mac.ff_cost
      ),
     2
    ) new_avg_cost
  from mac
  left join oc on oc.output=mac.code
  left join cc on cc.code=mac.code
  where mac.company_id=cc.company_id
  order by key_id, code
),
-- fetch invoice data 
mcaBase as(
  select
    cast('500100' as int64) account_code,
    company_id,
    extract(month from invoice_date) m,
    extract(year from invoice_date) y,
    i.state,
    i.invoice_type,
    invoice_id,
    invoice_reference,
    l.product_code,
    l.quantity,
    l.type line_type
  from `project.data.account_invoices` i
  ,unnest(lines) l
  where 
   invoice_type='out' and
    l.type='sale' and
     extract(
      year 
      from invoice_date
    )=2023
),
-- summed product invoice qty
mcag as(
  select 
    company_id, 
    m,
    y,
    account_code, 
    product_code, 
    sum(quantity) qty 
    from mcaBase 
    group by 
      company_id,
      m,
      y,
      account_code,
      product_code 
    having 
      regexp_contains(
        product_code,
        r"^(?i)(shipping|ship)"
      )=false
),
-- journal entries for P&L
t as(  
  select
    j.uuid,
    j.company_name, -- Will probably need update to SPLIT(j.company_name,' (')[OFFSET(0)]
    j.number,
    j.post_number,
    j.description,
    j.state,
    j.date,
    j.post_date,
    j.period_name,
    SPLIT(j.period_name,'-')[OFFSET(0)] pyr,
    j.origin_model,
    j.sale_payment_id, -- seemingly null on bank.statement
    l.account_name,
    l.account_code,
    l.account_type_name,
    l.account_type,
    l.debit,
    l.credit,
    l.due_date,
    l.description lineDescription,
    l.contact_name,
  from `project.data.journal_entries` j
  left join unnest(lines) l
),
-- add portfolio label
pl AS(
  select
    label,
    company_name
  from `project.data.portfolio`
),
-- manual summed cogs 
mc as(
  select 
    mcag.company_id,
    case when mcag.company_id = 1 then '3h'
         when mcag.company_id = 2 then 'V'
         when mcag.company_id = 3 then 'C'
         when mcag.company_id = 4 then 'N'
         when mcag.company_id = 5 then 'H'
         when mcag.company_id = 6 then 'A'
         when mcag.company_id = 8 then 'F'
      else concat(
        'ERR:[CTE=mc][CASE=OOB][value=company_id{',
        mcag.company_id,
        '}]'
      )
    end company_name,
    account_code,
    m,
    y,
    concat(
      y,
      '-',
      if(
        cast(
          m as int64
        )
        <10,
        concat(
          '0',
          m
        ),
        cast(
          m as string
        )
      )
    ) period_name,
    round(
      sum(
        mcag.qty*cost.new_avg_cost
        ),
       2
      ) debit,
      round(
      sum(
        mcag.qty*cost.new_avg_cost
      ),
     2
    )*-1 net
  from mcag 
  left join cost on (
    cost.code=mcag.product_code 
    and mcag.company_id = cost.company_id
  )
  group by 
    1,
    2,
    3,
    4,
    5,
    6
  order by 
    company_id, 
    m
), 
-- final manual cogs dataet
fmc as ( 
  select 
    'Cost of Goods Sold' account_type_name,
    'expense_cogs' account_type,
    'Cost of Goods Sold' account_name,
	cast(
		concat(
			period_name,
			'-01'
		)
	  as date
	) dt,
	cast(
		'0.00'
		as float64
	) credit,
    *
  from mc
),
-- remove bad account data and union in modified account data
u as (
	select
	  company_name,
	  number,
	  post_number,
	  period_name,
	  pyr,
	  account_name,
	  account_code,
	  account_type_name,
	  account_type,
	  debit,
	  credit,
	  lineDescription,
	  contact_name
	from t
	where (
		account_type_name != 'Cost of Goods Sold'
		and account_type != 'expense_cogs'
		and account_name != 'Cost of Goods Sold'
		and account_code != '500100'
	)
	union all
	select
	  company_name,
	  null number,
	  null post_number,
	  period_name,
	  y pyr,
	  account_name,
	  account_code,
	  account_type_name,
	  account_type,
	  debit,
	  credit,
	  'Manual Calc' lineDescription,
	  contact_name
	from fmc
)
-- final dataset for P&L Report
select 
  u.*,
  pl.label,
  cast(
	  concat(
		  period_name,
		  '-01'
	  )
	  as date
  ) period_month
from u
left join pl using (company_name)
