MERGE `project.dataset.vix` p
USING `project.dataset.vixStg` s
ON p.vix_date = s.vix_date
WHEN MATCHED THEN
  UPDATE SET
    p.vix_date = s.vix_date,
    p.vix_open = s.vix_open,
    p.vix_high = s.vix_high,
    p.vix_low = s.vix_low,
    p.vix_close = s.vix_close,
    p.pyts = s.pyts
WHEN NOT MATCHED THEN 
  INSERT(
    vix_date,
    vix_open,
    vix_high,
    vix_low,
    vix_close,
    pyts
  )
VALUES(
    s.vix_date,
    s.vix_open,
    s.vix_high,
    s.vix_low,
    s.vix_close,
    s.pyts
)
