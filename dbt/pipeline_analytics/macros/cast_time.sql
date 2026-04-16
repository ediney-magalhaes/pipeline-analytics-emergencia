{% macro cast_time(coluna) %}
    parse_time('%H:%M:%S', concat(coalesce({{ coluna }}, '00:00'), ':00'))
{% endmacro %}