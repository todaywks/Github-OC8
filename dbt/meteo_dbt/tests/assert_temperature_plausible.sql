select station_id, measured_at_utc, temperature_c
from {{ ref('fact_weather_measurements') }}
where temperature_c < -30 or temperature_c > 50