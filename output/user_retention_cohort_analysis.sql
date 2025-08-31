-- 1. Event date min/max aralığını al
WITH event_date_range AS (
  SELECT
    MIN(event_date) AS min_event_date,
    MAX(event_date) AS max_event_date
  FROM `metrics_analytics.rawdata_agg`
),

-- 2. Filtrelenmiş install'lar
installs AS (
  SELECT DISTINCT user_id, install_date
  FROM `metrics_analytics.rawdata_agg`, event_date_range
  WHERE install_date BETWEEN min_event_date AND max_event_date
),

-- 3. Retention event'leri (D0, D1, D3, D7, D15)
retention_events AS (
  SELECT
    i.user_id,
    i.install_date,
    DATE_DIFF(r.event_date, i.install_date, DAY) AS day
  FROM installs i
  JOIN `metrics_analytics.rawdata_agg` r
    ON i.user_id = r.user_id
  WHERE r.total_session_count > 0
    AND DATE_DIFF(r.event_date, i.install_date, DAY) IN (0, 1, 3, 7, 15)
),

-- 4. Günlük retained kullanıcı sayısı
pivoted_retention AS (
  SELECT
    install_date,
    COUNT(DISTINCT IF(day = 0, user_id, NULL)) AS d0_users,
    COUNT(DISTINCT IF(day = 1, user_id, NULL)) AS d1_users,
    COUNT(DISTINCT IF(day = 3, user_id, NULL)) AS d3_users,
    COUNT(DISTINCT IF(day = 7, user_id, NULL)) AS d7_users,
    COUNT(DISTINCT IF(day = 15, user_id, NULL)) AS d15_users
  FROM retention_events
  GROUP BY install_date
),

-- 5. Cohort boyutları
cohort_sizes AS (
  SELECT
    install_date,
    COUNT(DISTINCT user_id) AS total_users
  FROM installs
  GROUP BY install_date
)

-- 6. Nihai çıktı
SELECT
  p.install_date,
  ROUND(SAFE_DIVIDE(p.d0_users, c.total_users), 3) AS d0_retention,
  ROUND(SAFE_DIVIDE(p.d1_users, c.total_users), 3) AS d1_retention,
  ROUND(SAFE_DIVIDE(p.d3_users, c.total_users), 3) AS d3_retention,
  ROUND(SAFE_DIVIDE(p.d7_users, c.total_users), 3) AS d7_retention,
  ROUND(SAFE_DIVIDE(p.d15_users, c.total_users), 3) AS d30_retention
FROM pivoted_retention p
JOIN cohort_sizes c USING (install_date)
ORDER BY p.install_date