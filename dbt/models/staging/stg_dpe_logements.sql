-- Typage du DPE brut. Un DPE = une ligne (doublons techniques de téléchargement retirés).
with source as (
    select * from {{ source('raw', 'dpe_logements') }}
)

select
    numero_dpe,
    numero_dpe_remplace,
    try_cast(date_etablissement_dpe as date)                  as date_etablissement_dpe,
    code_insee_ban                                            as code_commune,
    nom_commune_ban                                           as nom_commune,
    code_departement_ban                                      as code_departement,
    identifiant_ban,
    lower(type_batiment)                                      as type_batiment,
    periode_construction,
    try_cast(annee_construction as integer)                   as annee_construction,
    try_cast(surface_habitable_logement as double)            as surface_habitable,
    upper(etiquette_dpe)                                      as etiquette_dpe,
    upper(etiquette_ges)                                      as etiquette_ges,
    try_cast(conso_5_usages_par_m2_ep as double)              as conso_energie_primaire_m2,
    try_cast(emission_ges_5_usages_par_m2 as double)          as emission_ges_m2,
    _loaded_at
from source
qualify row_number() over (partition by numero_dpe order by _loaded_at) = 1
