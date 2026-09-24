/*
  Répartition des étiquettes DPE par commune et type de logement.
  Sert aux barres empilées A→G du dashboard (et au filtre par période de construction).
*/
select
    code_commune || '-' || type_batiment || '-' || etiquette_dpe || '-' || coalesce(periode_construction, 'inconnue') as cle,
    code_commune,
    any_value(nom_commune)                  as nom_commune,
    any_value(code_departement)             as code_departement,
    type_batiment,
    coalesce(periode_construction, 'inconnue') as periode_construction,
    etiquette_dpe,
    count(*)                                as nb_logements
from {{ ref('int_dpe_logement_dernier') }}
group by code_commune, type_batiment, coalesce(periode_construction, 'inconnue'), etiquette_dpe
