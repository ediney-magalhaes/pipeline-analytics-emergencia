# ADR-002 — Tratamento de Dados Sensíveis e LGPD

## Contexto
As bases de fonte dos dados trazem informações sensíveis do paciente conforme a LGPD. Alguns desses dados como: idade, CEP, Cidade e Estado são necessários para avaliação do perfil do paciente. Porém dados de identificação como: nome completo e data de nascimento não fazem parte do escopo de análise, sendo necessário tratamento adequado já na leitura desses dados na fonte.

## Decisão
Aplicar métodos de anonimização e exclusão de dados sensíveis já na leitura dos dados antes mesmo de carrega-los à nuvem.
- **Exclusão:**
    - Nome completo do paciente
    - Data de nascimento

- **Anonimização:**
    - Número do prontuário
    - Número de atendimento

- **Permanência:**
    - Nome e CRM do médico atendente
    - Idade do paciente
    - CEP
    - Bairro
    - Cidade
    - Estado

## Justificativa
Dados que identificam expressamente o paciente não serão necessários para compor análise, como: nome completo e data de nascimento. São dados sensíveis que são utilizados no contexto hospitalar para assistência segura e não para análise de resultados;
Os dado de identificação via sistema operacional (cadastro) serão anonimizados já na leitura na fonte, isso evita exposição;
Já os dados necessários pará análise de perfil serão mantidos conforme descritos acima.

## Consequências
- **Positivas:**
    - Dados permanentes melhoram o entendimento do perfil de atendimento;
    - Dados anonimizados evitam exposição desnecessária.
    
- **Negativas:**
    - Exigência de controle na disponibilização do painel para visualização quando houver necessidade de analisar performance por médico (pseudonimização futura);
    - Alguns campos sobre o bairro podem estar ausente na fonte, exigindo enriquecimento futuro via CEP.