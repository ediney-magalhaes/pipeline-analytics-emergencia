select *
from {{ ref('atendimentos_pa') }}
where INICIO_CLASSIFICACAO is not null and INICIO_CLASSIFICACAO < DT_HR_TOTEM_RECEP