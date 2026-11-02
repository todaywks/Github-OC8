with infoclimat as (

    select
        station_id,
        'infoclimat'              as source_network,
        measured_at_utc,
        temperature_c,
        dew_point_c,
        humidity_pct,
        pressure_hpa,
        wind_speed_kmh,
        wind_gust_kmh,
        wind_direction_deg,
        precip_1h_mm,
        precip_3h_mm,
        null::numeric             as precip_rate_mm,
        null::numeric             as precip_accum_mm,
        null::numeric             as uv_index,
        null::numeric             as solar_radiation_wm2,
        visibility,
        cloud_cover,
        snow_depth,
        weather_code
    from {{ ref('stg_infoclimat__mesures') }}

),

wu as (

    select * from {{ ref('stg_wu_ichtegem') }}
    union all
    select * from {{ ref('stg_wu_la_madeleine') }}

),

wu_harmonized as (

    select
        station_id,
        'weather_underground'                                   as source_network,
        (measured_at_local at time zone 'Europe/Paris') at time zone 'UTC' as measured_at_utc,
        round((temperature_f - 32) / 1.8, 2)                    as temperature_c,
        round((dew_point_f - 32) / 1.8, 2)                      as dew_point_c,
        humidity_pct,
        round(pressure_inhg * 33.8639, 1)                       as pressure_hpa,
        round(wind_speed_mph * 1.609344, 1)                     as wind_speed_kmh,
        round(wind_gust_mph * 1.609344, 1)                      as wind_gust_kmh,
        {{ compass_to_degrees('wind_direction_compass') }}      as wind_direction_deg,
        null::numeric                                           as precip_1h_mm,
        null::numeric                                           as precip_3h_mm,
        round(precip_rate_in * 25.4, 2)                         as precip_rate_mm,
        round(precip_accum_in * 25.4, 2)                        as precip_accum_mm,
        uv_index,
        solar_radiation_wm2,
        null::numeric                                           as visibility,
        null::int                                               as cloud_cover,
        null::numeric                                           as snow_depth,
        null::int                                               as weather_code
    from wu

)

select * from infoclimat
union all
select * from wu_harmonized