-- Tüm zamanlar baz alınarak quantile yardımıyla 4 seviyeli segmentasyon yapılmıştır.
WITH d0_users AS (
  SELECT
    user_id,
    install_date,
    total_session_duration,
    match_start_count,
    iap_revenue
  FROM
    `metrics_analytics.rawdata_agg`
  WHERE
    event_date = install_date
),

with_quantiles AS (
  SELECT
    user_id,
    install_date,
    total_session_duration,
    match_start_count,
    iap_revenue,

    -- Quartile segmentleri (1: düşük, 4: yüksek)
    NTILE(4) OVER (ORDER BY total_session_duration) AS session_duration_segment,
    NTILE(4) OVER (ORDER BY match_start_count) AS match_segment,
    NTILE(4) OVER (ORDER BY iap_revenue) AS revenue_segment

  FROM d0_users
)

SELECT
  user_id,
  install_date,
  session_duration_segment,
  match_segment,
  revenue_segment
FROM with_quantiles