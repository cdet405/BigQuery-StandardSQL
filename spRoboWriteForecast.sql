-- creates table from raw forecast file, then merges created table to stage,
-- then calls procedure to merge stage and prod 
create or replace procedure `myproject.manifest.spRoboWriteForecast`(fileName string, fileType string)
begin
  -- create variables 
  declare response, retireCurrentStage, fileToTable, resetpd, uts, t, f, uris, location, stageRefresh string;
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
      skip_leading_rows = 1,
      uris = ['%s']
    );
    """,
    location,
    fileType,
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
  from %s
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
  execute immediate fileToTable;
  execute immediate response;
  execute immediate retireCurrentStage;
  execute immediate stageRefresh;
  execute immediate resetpd; 
  -- merges stage to prod
  call `myproject.manifest.spForecastVelocity`();
end;
