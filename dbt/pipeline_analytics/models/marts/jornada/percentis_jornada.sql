with arrays_percentis as(
    select
        SERVICO,
        competencia,
        approx_quantiles(minutos_espera_classificacao, 100) as minutos_espera_classificacao,
        approx_quantiles(minutos_duracao_classificacao, 100) as minutos_duracao_classificacao,
        approx_quantiles(minutos_espera_cadastro, 100) as minutos_espera_cadastro,
        approx_quantiles(minutos_duracao_cadastro, 100) as minutos_duracao_cadastro,
        approx_quantiles(minutos_espera_medica_pos_cadastro, 100) as minutos_espera_medica_pos_cadastro,
        approx_quantiles(minutos_duracao_atendimento_medico, 100) as minutos_duracao_atendimento_medico,
        approx_quantiles(minutos_pos_atendimento_ate_alta, 100) as minutos_pos_atendimento_ate_alta,
        approx_quantiles(minutos_permanencia_total, 100) as minutos_permanencia_total
    from {{ ref('atendimentos_pa') }}
    group by SERVICO, competencia
),

percentis_longos as(
    select
        SERVICO,
        competencia,
        etapas.nome_etapa,
        etapas.array_valores[offset(50)] as p50,
        etapas.array_valores[offset(90)] as p90
    from arrays_percentis,
    unnest([
        struct('Espera classificação' as nome_etapa, minutos_espera_classificacao as array_valores),
        struct('Duração classificação' as nome_etapa, minutos_duracao_classificacao as array_valores),
        struct('Espera cadastro' as nome_etapa, minutos_espera_cadastro as array_valores),
        struct('Duração cadastro' as nome_etapa, minutos_duracao_cadastro as array_valores),
        struct('Espera atendimento médico' as nome_etapa, minutos_espera_medica_pos_cadastro as array_valores),
        struct('Duração atendimento médico' as nome_etapa, minutos_duracao_atendimento_medico as array_valores),
        struct('Espera alta após atendimento médico' as nome_etapa, minutos_pos_atendimento_ate_alta as array_valores),
        struct('Tempo permanência' as nome_etapa, minutos_permanencia_total as array_valores)
    ]) as etapas
)

select * from percentis_longos