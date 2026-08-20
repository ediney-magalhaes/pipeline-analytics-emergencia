# dbt — pipeline-analytics-emergencia

## Sobre
Projeto dbt responsável pelas transformações dos dados da Emergência do hospital.
Lê os dados brutos do BigQuery Raw e os transforma em indicadores prontos para 
consumo no Power BI.

## Estrutura
```
dbt/
├── models/
│   ├── staging/          # Modelos de limpeza e tipagem — leem do Raw
│   │   ├── stg_atendimentos.sql
│   │   ├── stg_internacoes.sql
│   │   └── stg_movimentacoes.sql
│   └── marts/            # Modelos de negócio — leem do Staged
│       ├── atendimentos/
│       │   └── atendimentos_pa.sql
│       ├── ranking/
│       │   └── ranking_especialidades.sql
│       └── jornada/
│           ├── percentis_jornada.sql
│           └── volume_jornada.sql
├── seeds/                # Dados de referência estáticos
│   ├── dim_leitos.csv         # Cadastro de referência para as movimentações de leitos no hospital
│   └── seed_cid_capitulo.csv  # De-para CID-10 → Capítulo (nível agregado), 14.235 códigos únicos
├── macros/               # Macros reutilizáveis
└── dbt_project.yml       # Configuração do projeto
```

## Camadas

| Camada | Dataset BigQuery | Descrição |
|---|---|---|
| Staging | `staged` | Tipagem correta, colunas necessárias, sem regras de negócio |
| Marts | `marts` | Indicadores finais com flags de negócio prontos para o BI |

## Particionamento e Clusterização

Todas as tabelas staged e marts são particionadas por `competencia` (DATE), 
coluna extraída do nome do arquivo na ingestão (padrão: `tipo_YYYY_MM.csv`) 
e convertida de STRING para DATE no staged.

A clusterização é configurada por subpasta no `dbt_project.yml`:
- `marts/atendimentos/` — clusterizada por `SERVICO`, `CONVENIO` e `COR_CLASSIF`
- `marts/ranking/` — sem clusterização (tabela pequena, ~10 linhas por competência)
- `marts/jornada/` — sem clusterização (tabelas agregadas; `volume_jornada` ~131k linhas, 
  `percentis_jornada` ~96k linhas, após expansão para suportar os 6 filtros da Página 2 — 
  volume que pode justificar reavaliação futura de clusterização)

Detalhes da decisão no ADR-015.

Configuração centralizada no `dbt_project.yml`.

## Indicadores Gerados

| Campo | Modelo | Descrição |
|---|---|---|
| `fl_conversao` | atendimentos_pa | Atendimento convertido em internação (automático via JOIN ou confirmado na curadoria) |
| `fl_suspeito_conversao` | atendimentos_pa | Possível conversão com erro de cadastro de origem |
| `fl_retorno_48h` | atendimentos_pa | Paciente retornou ao PA em menos de 48h |
| `fl_evasao` | atendimentos_pa | Paciente evadiu sem alta médica |
| `turno` | atendimentos_pa | Turno de chegada derivado do horário do totem (Manhã, Tarde, Noite, Madrugada) |
| `faixa_etaria` | atendimentos_pa | Faixa etária do paciente derivada da idade |
| `faixa_sla` | atendimentos_pa | Classificação da permanência total em 4 categorias: Dentro da meta, Fora da meta, Muito fora da meta, e Alta não registrada (dado ausente tratado explicitamente) |
| `grupo_cid` | atendimentos_pa | Capítulo da CID-10 (nível agregado) via JOIN com seed `seed_cid_capitulo`, usado como filtro na Página 2 (Jornada do Paciente) |
| `minutos_espera_classificacao` a `minutos_permanencia_total` | atendimentos_pa | Durações por etapa da jornada do paciente — ver ficha técnica de métricas |
| `total_pontos` | ranking_especialidades | Indicador composto ponderado de desempenho por especialidade |
| `p50`, `p90` | percentis_jornada | Percentis de duração por etapa, competência e especialidade |
| `volume` | volume_jornada | Volume de atendimentos por marco da jornada, competência e especialidade (funil) |

## Comandos

Em produção, o dbt é executado automaticamente via Cloud Run Job (`dbt-pipeline-job`) 
após a ingestão dos 3 arquivos mensais. Os comandos abaixo servem como referência 
para desenvolvimento local:

```bash
dbt run                       # Executar todos os modelos
dbt run --select staging      # Executar só staging
dbt run --select marts        # Executar só marts
dbt test                      # Rodar os testes
dbt docs generate && dbt docs serve  # Documentação
```

## Testes

O projeto conta com 53 testes automatizados:

- `not_null` e `unique` nos campos-chave de staging e marts
- `not_null` em `competencia` em todas as tabelas (staged e marts)
- `accepted_values` nas flags binárias (0 ou 1)
- `accepted_values` em `turno` e `faixa_etaria`
- `accepted_values` nas posições do ranking (1 a 6)
- `dbt_utils.unique_combination_of_columns` no ranking (SERVICO + competencia)
- Testes de sequência temporal — cada etapa da jornada deve ocorrer após a
  anterior (ex: `cadastro_apos_classif_risco`, `atend_medico_apos_fim_cadastro`)
- Teste `percentis_p90_maior_p50` — garante consistência estatística entre os
  percentis calculados
- Teste singular `movimentacoes_nulos_invalidos` — valida que nenhuma linha com
  número de atendimento válido possui `Hora` ou `Destino` nulos

**Nota:** parte dos testes de sequência temporal captura inconsistências sem
correção possível na origem — esses casos são registrados na curadoria com
status `nao_corrigivel`, não `pendente` (ver interface de curadoria).

## Configuração
O projeto utiliza macro `generate_schema_name` para roteamento correto 
dos datasets `staged` e `marts` no BigQuery.
Detalhes de arquitetura em [docs/arquitetura.md](../docs/arquitetura.md).