/*
  Pivot des indicateurs INSEE : une ligne par commune, une colonne par indicateur,
  en gardant pour chaque indicateur sa période la plus récente.

  Millésimes dans l'édition 2026 : population et logements 2023 (recensement),
  niveau de vie et pauvreté 2023 (Filosofi).
*/
with dernier as (
    select *
    from {{ ref('stg_insee_indicateurs') }}
    qualify row_number() over (partition by code_commune, indicateur order by annee desc) = 1
)

select
    code_commune,
    any_value(nom_commune)                                                    as nom_commune,
    left(code_commune, 2)                                                     as code_departement,
    max(valeur) filter (where indicateur = 'POP')                             as population,
    max(valeur) filter (where indicateur = 'SUP')                             as superficie_km2,
    max(valeur) filter (where indicateur = 'MED_SL')                          as niveau_vie_median,
    max(valeur) filter (where indicateur = 'PR_MD60')                         as taux_pauvrete,
    max(valeur) filter (where indicateur = 'DWELLINGS')                       as nb_logements,
    max(valeur) filter (where indicateur = 'DWELLINGS_OCS_DW_MAIN')           as nb_residences_principales,
    max(valeur) filter (where indicateur = 'DWELLINGS_OCS_DW_MAIN_TSH_100')   as nb_proprietaires,
    max(valeur) filter (where indicateur = 'DWELLINGS_OCS_DW_VAC')            as nb_logements_vacants,
    max(valeur) filter (where indicateur = 'DWELLINGS_OCS_DW_SEC_DW_OCC')     as nb_residences_secondaires,
    bool_or(est_secret_statistique and indicateur = 'MED_SL')                 as niveau_vie_sous_secret
from dernier
group by code_commune
