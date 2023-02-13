-- Calculate Number of Days to Ship 
WITH so AS(
  SELECT
    o.id,
    o.order_number,
    o.order_id,
    o.order_reference,
    o.order_date,
    o.confirmation_time,
    o.state,
    o.company_name
  FROM 
    `REDACTED_PROJECT.REDACTED_HOST.sales_orders` o,
    UNNEST(lines) l
  WHERE
    DATE(o.order_date) >= (
      CURRENT_DATE() - INTERVAL 30 DAY
    )
    AND l.line_type = 'sale'
    AND o.state NOT IN(
      'cancel', 'failed', 'ignored', 'draft'
    )
  GROUP BY
    o.id,
    o.order_number,
    o.order_id,
    o.order_reference,
    o.order_date,
    o.confirmation_time,
    o.state,
    o.company_name
),
s AS(
  SELECT
    m.order_id,
    shipped_date,
    company_name
  FROM
    `REDACTED_PROJECT.REDACTED_HOST.shipments`,
    UNNEST(moves) m
  WHERE 
    m.move_type = 'outgoing'
    AND m.to_location_type = 'customer'
  GROUP BY
    m.order_id,
    shipped_date,
    company_name
),
ot AS (
  SELECT 
    id, 
    DATE(
      IF (
        EXTRACT(
          HOUR 
          FROM 
            confirmation_time
        )-5 >= 15, 
        DATE(order_date) + INTERVAL 1 DAY, 
        DATE(order_date)
      )
    ) AS orderTime 
  FROM 
    so
), 
dn AS (
  SELECT 
    id, 
    EXTRACT(
      dayofweek 
      FROM 
        ot.orderTime
    ) dow, 
    CASE WHEN EXTRACT(
      DAYOFWEEK 
      FROM 
        ot.orderTime
    ) IN(1, 7) THEN 6 ELSE EXTRACT(
      DAYOFWEEK 
      FROM 
        ot.orderTime
    ) END AS rdow 
  FROM 
    so 
    JOIN ot USING (id)
), 
rot AS (
  SELECT 
    id, 
    DATE(
      CASE WHEN dn.dow = 1 THEN DATE(ot.orderTime) - INTERVAL 2 DAY WHEN dn.dow = 7 THEN DATE(ot.orderTime) - INTERVAL 1 DAY ELSE DATE(ot.orderTime) END
    ) as wkdOrderTime 
  FROM 
    dn 
    JOIN ot using (id)
)
SELECT 
  so.order_id, 
  so.order_number, 
  so.order_reference, 
  so.order_date, 
  -- actual order date
  ot.orderTime, 
  -- revised order date based on cutoff
  rot.wkdOrderTime, 
  -- revised based on workingdays
  dn.dow, 
  -- actual day of the week
  dn.rdow, 
  -- revised day of the week
  IFNULL(
    CAST(s.shipped_date AS STRING), 
    'notShipped'
  ) shippedDate, 
  CASE WHEN s.shipped_date is NULL THEN DATE_DIFF(
    CURRENT_DATE, 
    DATE(orderTime), 
    DAY
  ) WHEN dn.rdow = 6 THEN (
    DATE_DIFF(
      DATE(shipped_date), 
      DATE(orderTime), 
      DAY
    ) -2
  ) ELSE DATE_DIFF(
    DATE(shipped_date), 
    DATE(orderTime), 
    DAY
  ) END AS daysToShip, 
  so.state, 
  so.company_name 
FROM 
  so 
  JOIN ot USING (id) 
  JOIN dn USING (id) 
  JOIN rot USING (id) 
  LEFT JOIN s ON so.order_id = s.order_id AND so.company_name = s.company_name 
