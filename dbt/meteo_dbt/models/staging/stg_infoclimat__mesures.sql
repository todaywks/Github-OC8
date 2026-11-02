
with source as (

    select * from {{ source('raw', 'infoclimat') }}

),

mesures as (

    select m
    from source,
         jsonb_each(source.hourly) as h(station_key, station_mesures),
         jsonb_array_elements(h.station_mesures) as m
    where h.station_key <> '_params'

)

select
    m->>'id_station'                            as station_id,
    (m->>'dh_utc')::timestamp                   as measured_at_utc,
    nullif(m->>'temperature', '')::numeric      as temperature_c,
    nullif(m->>'point_de_rosee', '')::numeric   as dew_point_c,
    nullif(m->>'humidite', '')::numeric         as humidity_pct,
    nullif(m->>'pression', '')::numeric         as pressure_hpa,
    nullif(m->>'vent_moyen', '')::numeric       as wind_speed_kmh,
    nullif(m->>'vent_rafales', '')::numeric     as wind_gust_kmh,
    nullif(m->>'vent_direction', '')::numeric   as wind_direction_deg,
    nullif(m->>'pluie_1h', '')::numeric         as precip_1h_mm,
    nullif(m->>'pluie_3h', '')::numeric         as precip_3h_mm,
    nullif(m->>'visibilite', '')::numeric       as visibility,
    nullif(m->>'nebulosite', '')::int          as cloud_cover,
    nullif(m->>'neige_au_sol', '')::numeric     as snow_depth,
    nullif(m->>'temps_omm', '')::int            as weather_code
from mesures