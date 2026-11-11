select station_id, measured_at_utc, humidity_pct
from {{ ref('fact_weather_measurements') }}
where humidity_pct < 0 or humidity_pct > 100