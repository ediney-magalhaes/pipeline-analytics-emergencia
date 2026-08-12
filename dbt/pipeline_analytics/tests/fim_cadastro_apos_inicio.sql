select *
from {{ ref('atendimentos_pa') }}
where FIM_CAD_RECEP is not null and FIM_CAD_RECEP < DH_CADASTRO_RECEPCAO