select *
from {{ ref('atendimentos_pa') }}
where DH_CADASTRO_RECEPCAO is not null and DH_CADASTRO_RECEPCAO < DT_HR_CLASSIF_RISCO