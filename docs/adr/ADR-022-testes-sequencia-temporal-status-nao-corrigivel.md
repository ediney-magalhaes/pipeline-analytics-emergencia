# ADR-022 — Testes de Sequência Temporal Individualizados e Status "Não Corrigível" na Curadoria

**Data:** 2026-08-12

## Contexto

Durante a construção da Página 2 (Jornada do Paciente), foi criado o teste
`duracoes_jornada_nao_negativas`, agrupando seis comparações de sequência
temporal (classificação, cadastro, atendimento médico) numa única condição
com `OR`, na tentativa de reduzir repetição de código. Esse desenho violou
a convenção já estabelecida no projeto, onde cada teste de sequência
temporal isola uma única comparação (ex: `classif_risco_apos_totem`,
`fim_atend_medico_apos_inicio`), convenção que existe justamente para que
o nome do teste, ao falhar, já identifique a etapa problemática sem
necessidade de investigação adicional.

O efeito colateral apareceu na interface de curadoria: os 217 casos
capturados pelo teste agrupado apareciam com o rótulo genérico
`duracoes_jornada_nao_negativas`, sem indicar qual das seis etapas
realmente falhou, tornando os casos impossíveis de revisar sem consulta
manual aos dados brutos de cada atendimento.

Durante a tentativa de revisão desses casos, um segundo problema foi
identificado: para a maioria das inconsistências de sequência temporal
(ex: `DH_CADASTRO_RECEPCAO < DT_HR_CLASSIF_RISCO`), não existe, na origem,
um valor real recuperável para correção, o dado incorreto já está
consolidado no sistema hospitalar (MV) e não será alterado. A prática
até então adotada, repetir o valor de um campo adjacente para "corrigir"
o dado e evitar duração negativa, constituía invenção de informação, não
correção, mascarando o problema em vez de expô-lo.

## Decisão

**Parte 1 — Testes individualizados.** O teste agrupado
`duracoes_jornada_nao_negativas` foi removido e substituído por cinco
testes singulares, cada um isolando uma única comparação de sequência
temporal (`classificacao_apos_totem_inicio`,
`classif_risco_apos_inicio_classificacao`, `cadastro_apos_classif_risco`,
`fim_cadastro_apos_inicio`, `atend_medico_apos_fim_cadastro`), seguindo a
convenção já estabelecida no projeto.

**Parte 2 — Proteção contra duração negativa.** O modelo `atendimentos_pa`
passou a verificar, em cada campo de duração, se o timestamp de destino é
anterior ao de origem, retornando `null` nesse caso, em vez de um valor
negativo. A etapa `minutos_pos_atendimento_ate_alta` (fim do atendimento
médico → alta) foi removida do modelo: em ~82% dos atendimentos
`DT_HR_ALTA` antecede `FIM_ATD_MEDICO`, não por erro de dado, mas por uma
particularidade operacional (registro de alta antecede o fechamento do
atendimento pelo médico no sistema), sem uma sequência confiável entre os
dois eventos, a duração não constitui uma métrica válida.

**Parte 3 — Status "não corrigível" na curadoria.** Adicionado o status
`nao_corrigivel` à tabela `curadoria_inconsistencias`, distinto de
`pendente` e `revisado`. Os cinco testes de sequência temporal cujas
falhas não têm correção real disponível na origem (`TESTES_SEM_CORRECAO`
em `populate_curadoria.py`) passam a ser inseridos diretamente com esse
status, em vez de `pendente`. Como a interface de curadoria (`main.py`)
já filtra exclusivamente por `status = 'pendente'`, nenhuma alteração de
interface foi necessária, os casos deixam de aparecer na tela de revisão
automaticamente.

## Funcionamento

Os testes de sequência temporal continuam rodando normalmente a cada
execução do dbt, preservando a visibilidade do volume de inconsistências
por competência (uso futuro: painel de correções vs. casos sem correção,
medindo esforço de retrabalho da equipe). O que muda é apenas o destino
do registro: `TESTES_SEM_CORRECAO` decide, em `montar_registro()`, se o
status inicial é `pendente` (segue para revisão humana) ou
`nao_corrigivel` (registrado para fins estatísticos, sem ação esperada).

Após o deploy (`v40`/`v41`), os 217 registros que haviam sido inseridos
incorretamente com `tipo = "nao_mapeado"` (efeito colateral do teste
agrupado, cujo nome não constava em `TIPO_POR_TESTE`) foram removidos
manualmente da `curadoria_inconsistencias` e recriados pela execução
seguinte do pipeline, já com `teste` e `status` corretos.

## Alternativas Consideradas

| Alternativa | Motivo da rejeição |
|---|---|
| Manter teste agrupado e adicionar campo/valor capturado por comparação | Contrariava a convenção já estabelecida (um teste = uma regra específica); a informação "qual etapa falhou" já está implícita no nome do teste, não precisa ser reconstruída em tempo de execução |
| Usar `severity: warn` no dbt para os testes sem correção | Já testado anteriormente no projeto (testes de `not_null` em `stg_movimentacoes`) e descartado: rebaixa a severidade de todo o teste indistintamente, e não persiste histórico — impede o painel futuro de taxa de correção vs. sem correção |
| Continuar "corrigindo" com valor repetido de campo adjacente | Constitui invenção de dado; mascara inconsistência real sem resolvê-la, tornando a métrica de qualidade de dado menos confiável, não mais |

## Consequências

- Positivas:
  - Interface de curadoria mostra apenas casos genuinamente acionáveis
  - Nome do teste voltou a identificar univocamente a etapa com problema
  - Volume de inconsistências sem correção possível permanece rastreável
    para análise futura de qualidade de dado na origem
  - Nenhum dado é mais inventado durante a curadoria
- Negativas:
  - `minutos_pos_atendimento_ate_alta` deixou de existir como métrica —
    a pergunta "quanto tempo entre o fim do atendimento médico e a alta"
    não é respondida enquanto o sistema de origem não registrar os dois
    eventos em ordem confiável
  - O padrão `TESTES_SEM_CORRECAO` é uma lista mantida manualmente em
    `populate_curadoria.py`; um teste novo de sequência temporal sem
    correção possível exige atualização manual dessa lista, sob risco de
    repetir o efeito colateral do `nao_mapeado`