select *
from {{ ref('percentis_jornada') }}
where p90 < p50
