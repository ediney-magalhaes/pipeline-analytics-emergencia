# ADR-021 — Correção: Suspeitos de Conversão Ausentes na Curadoria Unificada

**Data:** 2026-07-22

## Contexto

Quando a interface de curadoria foi unificada para tratar quatro tipos de
inconsistência (`conversao`, `logica_negocio`, `sequencia_temporal`,
`integridade`) através de uma tabela central (`curadoria_inconsistencias`,
ADR-017/ADR-020), o mecanismo de auto-população (`populate_curadoria.py`)
foi desenhado para ler apenas falhas de testes do dbt (`run_results.json`).

O campo `fl_suspeito_conversao` não é um teste que falha, é uma flag de
negócio calculada diretamente no modelo `atendimentos_pa`, sempre presente,
independente de qualquer teste. Como o script nunca consultava essa flag
diretamente, nenhum suspeito de conversão foi inserido na
`curadoria_inconsistencias` desde a unificação, o tipo `conversao` nunca
apareceu na interface, para nenhuma competência, mesmo com o dbt calculando
suspeitos normalmente todo mês (confirmado: 2 a 8 suspeitos por mês entre
fevereiro e junho/2026, todos invisíveis à revisão humana).

O problema só foi percebido em 22/07/2026, durante a carga da competência
de janeiro/2026, quando a operadora notou a ausência de casos de conversão
que normalmente aparecem todo mês.

## Decisão

Adicionar ao `populate_curadoria.py` uma nova função,
`buscar_suspeitos_conversao()`, que consulta diretamente
`marts.atendimentos_pa WHERE fl_suspeito_conversao = 1`, em paralelo à
leitura de falhas de teste, não substituindo-a. Os suspeitos encontrados
são convertidos para o mesmo formato de registro dos demais tipos (via
`montar_registro`, com `teste = "fl_suspeito_conversao"` fixo e
`tipo = "conversao"`) e inseridos na mesma tabela central, passando pelo
mesmo filtro de idempotência (`filtrar_novos`) já existente.

Foi necessário também remover o `return` antecipado no início da função
`main()`, que interrompia toda a execução quando não havia nenhuma falha
de teste, o que teria impedido a busca de suspeitos de conversão em
meses sem nenhuma outra inconsistência.

## Funcionamento

Após o deploy (`v37`), o Cloud Run Job foi executado manualmente uma vez
(fora do fluxo de upload) para popular retroativamente todas as
competências já carregadas na `marts` (fevereiro a junho/2026, além de
janeiro). As decisões de conversão já existentes na tabela
`curadoria_conversao` (tomadas antes da descoberta do problema, por
consulta direta ao BigQuery) foram sincronizadas via `UPDATE` direto na
`curadoria_inconsistencias`, evitando revisão duplicada na interface.

## Alternativas Consideradas

| Alternativa | Motivo da rejeição |
|---|---|
| Criar teste dbt singular para `fl_suspeito_conversao` | Distorce o propósito de teste do dbt (que valida qualidade/integridade) para carregar uma flag de negócio que sempre existe por design, não uma falha |
| Manter suspeitos de conversão em fluxo separado, fora da tabela central | Reintroduziria a fragmentação que a unificação (ADR-017) buscou eliminar; a operadora precisaria checar dois lugares |

## Consequências

- Positivas:
  - Suspeitos de conversão voltam a ser visíveis e revisáveis pela interface, para todas as competências, incluindo carga histórica futura
  - Nenhuma alteração na interface (`curadoria.html`) ou no roteamento de decisões (`main.py`) foi necessária, o problema estava isolado na etapa de detecção
- Negativas:
  - Entre a unificação da interface e esta correção, um número não determinado de suspeitos de conversão deixou de receber revisão humana em tempo hábil, embora nenhum dado tenha sido perdido (a flag permanece calculada corretamente na `marts`)
  - Reforça a necessidade de um mecanismo de observabilidade que alerte quando uma categoria de inconsistência esperada deixa de gerar registros (item já previsto no roadmap, seção "Observabilidade Analítica")