{% macro extract_number(column_name) -%}
    substring({{ column_name }} from '-?[0-9]+[.]?[0-9]*')::numeric
{%- endmacro %}