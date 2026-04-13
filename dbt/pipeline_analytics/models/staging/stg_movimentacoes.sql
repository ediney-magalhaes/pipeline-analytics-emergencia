with source as (
    select * from {{source('raw', 'movimentacoes')}}
),
transformado as(
    select
        Atendimento,
        Destino
    from source
)
select * from transformado