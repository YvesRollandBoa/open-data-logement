-- Typage et renommage du DVF brut. Aucune règle métier ici : une ligne source = une ligne.
with source as (
    select * from {{ source('raw', 'dvf_mutations') }}
)

select
    id_mutation,
    cast(date_mutation as date)                                   as date_mutation,
    year(cast(date_mutation as date))                             as annee,
    nature_mutation,
    try_cast(replace(valeur_fonciere, ',', '.') as double)        as valeur_fonciere,
    code_postal,
    code_commune,
    nom_commune,
    code_departement,
    id_parcelle,
    lot1_numero,
    try_cast(nombre_lots as integer)                              as nombre_lots,
    code_type_local,
    type_local,
    try_cast(surface_reelle_bati as double)                       as surface_reelle_bati,
    try_cast(nombre_pieces_principales as integer)                as nombre_pieces_principales,
    try_cast(surface_terrain as double)                           as surface_terrain,
    try_cast(longitude as double)                                 as longitude,
    try_cast(latitude as double)                                  as latitude,
    _loaded_at
from source
