-- force complete rebuild of forecast tables
create or replace procedure `myproject.manifest.spRoboRebuildForecast`(fileName STRING, fileType STRING)
begin
  -- create variables 
  declare response, retireCurrentStage, fileToTable, resetpd, uts, t, f, ft, param,  uris, location, stageRefresh, m, purgeProdGroup, purgeProd, rebuildProd, rebuildProdGroup string;
  declare rawfpa, ffpa array<int64>;
  declare cw, ew, sp, ep, d, w int64;
  set uts = concat(
    "_",
    cast(
      unix_seconds(
        current_timestamp(
        )
      ) 
      as string
    )
  );
  set ft = fileType;
  set param = if(
    lower(
      ft
    ) = 'csv',
    "skip_leading_rows = 1,",
    ""
  );
  set t = fileName;
  set f = fileName;
  set t = if(
    (
      select 
        count(1) cnt 
      from manifest.__TABLES_SUMMARY__ 
      where table_id = t
    )>0, 
    concat(
      t,
      uts
    ), 
   t
  );
  set response = if(
    t<>f,
    concat(
      "table ",
      f,
      " already exists. created table as ",
      t
    ),
    concat(
      "created table ",
      t
    )
  );
  set uris = concat(
    "gs://json-test-bucket-20221101/forecastVelocityCSV/",
    f,
    ".",
    fileType
  );
  set location = concat(
    "`myproject.manifest.",
    t,
    "`"
  );
  set fileToTable = format(
    """
    load data into %s
    from files (
      format = '%s',
      %s
      uris = ['%s']
    );
    """,
    location,
    fileType,
    param,
    uris
  );
  set retireCurrentStage = format(
    """
    update `myproject.manifest.forecastVelocityStg`
    set active = false
    where active = true;
    """
  );
  set stageRefresh = format(
    """
    insert into `myproject.manifest.forecastVelocityStg`(
      company_name,
      product_code,
      weekNum,
      qty,
      weekPeriod,
      runDate,
      active,
      mqty,
      confidencyLevel,
      previousActual,
      sid  
    )
    select
      'company' company_name,
      sku product_code, 
      week weekNum, 
      qty, 
      weekPeriod, 
      current_date() runDate,
      true active,
      mqty,
      cL confidencyLevel,
      LTM26 previousActual,
      sync_id sid
  FROM %s
    """,
    location
  );
  set resetpd = format(
    """
    update `myproject.manifest.forecastVelocity`
    set pd = null
    where 1=1;
    """
  );
  set cw = extract(
    isoweek from 
    current_date()
  );
  set ew = extract(
    isoweek from
    current_date() + interval 13 week
  );
  set sp = (
    select
     distinct
      weekPeriod
    from `myproject.manifest.forecastVelocityStg`
    where weekNum = cw 
      and active = true
  );
  set rawfpa = (
    select
      array_agg(
        distinct
         weekPeriod
        order by
         weekPeriod asc
      )
    from `myproject.manifest.forecastVelocityStg`
    where active = true
  );
  set ep = ifnull(
    (
      select
       distinct
        weekPeriod
      from `myproject.manifest.forecastVelocityStg`
      where weekNum = ew
        and active = true
    ),
    (
      select
        array_reverse(
          rawfpa
        )[
          offset(
            0
          )
        ]
    )
  );
  set ffpa = (
    select 
      array_agg(
        distinct
         weekPeriod
        order by 
          weekPeriod asc
      )
    from `myproject.manifest.forecastVelocityStg`
    where active = true
      and weekPeriod
        between sp 
          and ep
  );
  set w = (
    select
      array_length(
        ffpa
      )
     -1
  );
  set d = w*7;
  set m = concat(
    'DSI Based on a ',
    w,
    ' Week Forecast'
  );
  set purgeProdGroup = format(
    """
    truncate table `myproject.manifest.forecastVelocityGroup`
    """
  );
  set purgeProd = format(
    """
    truncate table `myproject.manifest.forecastVelocity`
    """
  );
  set rebuildProd = format(
    """
    insert into `myproject.manifest.forecastVelocity`
    (
      company_name,
      product_code,
      weekNum,
      qty,
      weekPeriod,
      runDate,
      active,
      pd
    )
    select
      company_name,
      product_code,
      weekNum,
      mqty qty,
      weekPeriod,
      runDate,
      active,
      current_date() pd
    from `myproject.manifest.forecastVelocityStg`
    where weekPeriod in unnest(
      %t
    )
      and active = true
    """,
    ffpa
  );
  set rebuildProdGroup = format(
    """
    insert into `myproject.manifest.forecastVelocityGroup`
    (
      arrayInfo,
      currweek,
      endweek ,
      startperiod,
      endperiod,
      weeksConsidered,
      product_code,
      totalForecastVelocity,
      forecastDailyAverage
    )
    select
      %s as arrayInfo,
      %d as currweek,
      %d as endweek,
      %d as startperiod,
      %d as endperiod,
      %d as weeksConsidered,
      product_code,
      sum(
        mqty
      ) total,
      round(
        sum(
          mqty
          )
        /%d,
       3
      ) dailyAverage
    from `myproject.manifest.forecastVelocityStg`
    where weekPeriod in unnest(
      %t
    )
      and active = true
    group by product_code
    """,
    m,
    cw,
    ew,
    sp,
    ep,
    w,
    d,
    ffpa
  );
  begin transaction;
    execute immediate fileToTable; -- Creates New Table From Forecast File (CSV/JSON/ARVO/PARQUET).
    execute immediate retireCurrentStage; -- Sets all active stage records inactive.
    execute immediate stageRefresh; -- inserts new records to stage that are set to active.
    execute immediate resetpd; -- pd is an exit criteria used by dashboard for scheduled prod updates.
    execute immediate purgeProdGroup; -- deletes all records in prod grouped table.
    execute immediate purgeProd; -- deletes all prod records in ungrouped table.
    execute immediate rebuildProd; -- rebuilds prod table using new stage records.
    execute immediate rebuildProdGroup; -- rebuilds prod grouped table using new stage records.
  commit transaction;
  exception when error then
    select @@error.message;
  rollback transaction;
end;
