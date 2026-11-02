select
    station_id,
    station_name,
    source_network,
    station_type,
    latitude,
    longitude,
    elevation_m,
    city,
    state,
    country,
    hardware,
    software,
    license_name,
    license_source
from {{ ref('int_weather_stations') }}