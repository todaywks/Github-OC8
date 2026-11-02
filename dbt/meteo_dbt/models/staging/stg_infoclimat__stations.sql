with source as (

    select * from {{ source('raw', 'infoclimat') }}

)

select
    s->>'id'                    as station_id,
    s->>'name'                  as station_name,
    s->>'type'                  as station_type,
    (s->>'latitude')::numeric   as latitude,
    (s->>'longitude')::numeric  as longitude,
    (s->>'elevation')::numeric  as elevation_m,
    s->'license'->>'license'    as license_name,
    s->'license'->>'source'     as license_source,
    s->'license'->>'url'        as license_url,
    s->'license'->>'metadonnees' as metadata_url
from source,
     jsonb_array_elements(source.stations) as s