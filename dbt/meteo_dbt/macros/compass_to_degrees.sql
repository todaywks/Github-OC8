{% macro compass_to_degrees(column_name) -%}
    case {{ column_name }}
        when 'N'   then 0.0   when 'NNE' then 22.5  when 'NE'  then 45.0   when 'ENE' then 67.5
        when 'E'   then 90.0  when 'ESE' then 112.5 when 'SE'  then 135.0  when 'SSE' then 157.5
        when 'S'   then 180.0 when 'SSW' then 202.5 when 'SW'  then 225.0  when 'WSW' then 247.5
        when 'W'   then 270.0 when 'WNW' then 292.5 when 'NW'  then 315.0  when 'NNW' then 337.5
    end
{%- endmacro %}