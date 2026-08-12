select *
from {{ ref('atendimentos_pa') }}
where INI_ATD_MEDICO is not null and INI_ATD_MEDICO < FIM_CAD_RECEP