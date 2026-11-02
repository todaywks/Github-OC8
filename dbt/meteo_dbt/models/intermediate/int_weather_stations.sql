with infoclimat as (
    select
        station_id::text            as station_id,
        'infoclimat'                as source_network,
        station_name,
        station_type,
        latitude::numeric           as latitude,
        longitude::numeric          as longitude,
        elevation_m::numeric        as elevation_m,
        null::text                  as city,
        null::text                  as state,
        'France'                    as country,
        null::text                  as hardware,
        null::text                  as software,
        license_name,
        license_source
    from {{ ref('stg_infoclimat__stations') }}
),

wu as (
    select
        station_id::text            as station_id,
        'weather_underground'       as source_network,
        station_name,
        'amateur'                   as station_type,
        latitude::numeric           as latitude,
        longitude::numeric          as longitude,
        elevation_m::numeric        as elevation_m,
        city,
        state,
        country,
        hardware,
        software,
        null::text                  as license_name,
        null::text                  as license_source
    from {{ ref('wu_stations_metadata') }}
)

select * from infoclimat
union all
select * from wu