-- Indicateurs INSEE au niveau commune, format long, renommés en français.
-- Les valeurs sous secret statistique (CONF_STATUS = 'C') sont mises à NULL
-- pour qu'aucune ne soit utilisée par erreur dans un calcul.
with source as (
    select * from {{ source('raw', 'insee_comparateur') }}
    where GEO_OBJECT = 'COM'
)

select
    GEO                                        as code_commune,
    GEO_LABEL                                  as nom_commune,
    TAB_MEASURE                                as indicateur,
    TAB_MEASURE_LABEL                          as libelle_indicateur,
    cast(TIME_PERIOD as integer)               as annee,
    case when CONF_STATUS = 'C' then null else OBS_VALUE end as valeur,
    coalesce(CONF_STATUS = 'C', false)         as est_secret_statistique,
    GEO_REF                                    as millesime_geographie
from source
