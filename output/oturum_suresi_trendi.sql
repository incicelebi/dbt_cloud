-- Bu query ortalama session süresi ve önceki 7 günün ortama session süresini hesaplayarak change hesaplar
WITH daily_stats AS (
  SELECT
    event_date,
    SAFE_DIVIDE(SUM(total_session_duration), NULLIF(SUM(total_session_count), 0)) AS avg_session_duration
  FROM
    `metrics_analytics.rawdata_agg`
  GROUP BY
    event_date
),

with_trend AS (
  SELECT
    event_date,
    avg_session_duration,

    -- Önceki 7 günün ortalama oturum süresi
    AVG(avg_session_duration) OVER (
      ORDER BY event_date
      ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
    ) AS avg_prev_7_days

  FROM daily_stats
)

SELECT
  event_date,
  ROUND(avg_session_duration, 2) AS avg_session_duration,
  ROUND(avg_prev_7_days, 2) AS avg_prev_7_days,
  ROUND(
    SAFE_DIVIDE(avg_session_duration - avg_prev_7_days, avg_prev_7_days) * 100,
    2
  ) AS pct_change_from_prev_7_days
FROM with_trend
ORDER BY event_date