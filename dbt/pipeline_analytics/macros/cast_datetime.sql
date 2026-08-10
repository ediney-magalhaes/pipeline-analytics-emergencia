{% macro cast_datetime(coluna) %}
-- converte texto para datetime. Trata também números seriais do Excel (dias desde 1899-12-30),
-- que aparecem quando uma célula de data perde a formatação na origem
case
    -- identifica valores puramente numéricos (ex: 45979.6125)
    -- assinatura de número serial do Excel, não um datetime válido
    when regexp_contains({{coluna}}, r'^[0-9]+\.?[0-9]*$') then
    -- soma à data-base do Excel (1899-12-30) a quantidade de dias do valor,
    -- convertida para segundos inteiros (exigência do DATETIME_ADD)
    datetime_add(datetime '1899-12-30 00:00:00', interval cast(round(cast({{coluna}} as float64) * 86400) as int64) second)
    -- comportamento padrão, valor já vem em formato de datetime reconhecível
    else cast({{coluna}} as datetime)
end
{% endmacro %}