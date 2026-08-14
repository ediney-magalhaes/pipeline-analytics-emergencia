with volumes as(
    select
        SERVICO,
        competencia,
        countif(DT_HR_TOTEM_RECEP is not null) as volume_totem,
        countif(INICIO_CLASSIFICACAO is not null) as volume_inicio_classificacao,
        countif(DT_HR_CLASSIF_RISCO is not null) as volume_fim_classificacao,
        countif(DH_CADASTRO_RECEPCAO is not null) as volume_inicio_cadastro,
        countif(FIM_CAD_RECEP is not null) as volume_fim_cadastro,
        countif(INI_ATD_MEDICO is not null) as volume_inicio_medico,
        countif(FIM_ATD_MEDICO is not null) as volume_fim_medico,
        countif(DT_HR_ALTA is not null) as volume_alta
    from {{ ref('atendimentos_pa') }}
    group by SERVICO, competencia
),

volumes_longos as(
    select
        SERVICO,
        competencia,
        etapas.nome_etapa,
        etapas.volume,
        etapas.ordem
    from volumes,
    unnest([
        struct('Totem' as nome_etapa, volume_totem as volume, 1 as ordem),
        struct('Início Classificação' as nome_etapa, volume_inicio_classificacao as volume, 2 as ordem),
        struct('Fim Classificação' as nome_etapa, volume_fim_classificacao as volume, 3 as ordem),
        struct('Início Cadastro' as nome_etapa, volume_inicio_cadastro as volume, 4 as ordem),
        struct('Fim Cadastro' as nome_etapa, volume_fim_cadastro as volume, 5 as ordem),
        struct('Início Médico' as nome_etapa, volume_inicio_medico as volume, 6 as ordem),
        struct('Fim Médico' as nome_etapa, volume_fim_medico as volume, 7 as ordem),
        struct('Alta' as nome_etapa, volume_alta as volume, 8 as ordem)
    ]) as etapas
)

select * from volumes_longos