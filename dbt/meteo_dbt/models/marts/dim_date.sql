with days as (
    select distinct measured_at_utc::date as date_day
    from {{ ref('int_weather_measurements') }}
)

select
    to_char(date_day, 'YYYYMMDD')::int  as date_key,
    date_day,
    extract(year  from date_day)::int   as year,
    extract(month from date_day)::int   as month,
    extract(day   from date_day)::int   as day,
    to_char(date_day, 'TMDay')          as day_name,
    extract(isodow from date_day) in (6, 7) as is_weekend
from days