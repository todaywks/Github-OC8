with source as (

    select * from {{ source('raw', 'wu_la_madeleine') }}

),

mesures as (

    -- les lignes vides (une par onglet) n'ont que sheet_name renseigné
    select * from source where "Time" is not null

)

select
    'ILAMAD25'                                    as station_id,
    to_date(lpad(sheet_name::bigint::text, 6, '0'), 'DDMMYY')
        + "Time"::time                            as measured_at_local,
    {{ extract_number('"Temperature"') }}         as temperature_f,
    {{ extract_number('"Dew_Point"') }}           as dew_point_f,
    {{ extract_number('"Humidity"') }}            as humidity_pct,
    {{ extract_number('"Pressure"') }}            as pressure_inhg,
    "Wind"                                        as wind_direction_compass,
    {{ extract_number('"Speed"') }}               as wind_speed_mph,
    {{ extract_number('"Gust"') }}                as wind_gust_mph,
    {{ extract_number('"Precip__Rate_"') }}       as precip_rate_in,
    {{ extract_number('"Precip__Accum_"') }}      as precip_accum_in,
    "UV"                                          as uv_index,
    {{ extract_number('"Solar"') }}               as solar_radiation_wm2
from mesures