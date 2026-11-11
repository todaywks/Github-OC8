select station_id, measured_at_utc, count(*) as n
from {{ ref('fact_weather_measurements') }}
group by station_id, measured_at_utc
having count(*) > 1