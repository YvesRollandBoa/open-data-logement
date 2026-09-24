/*
  Prix immobiliers par commune, année et type de logement.
  Médiane plutôt que moyenne : robuste aux ventes atypiques restantes.
  Les cellules avec moins de 5 ventes sont gardées mais signalées (`est_fiable`),
  pour que le dashboard puisse les griser au lieu d'afficher un chiffre trompeur.
*/
with ventes as (
    select * from {{ ref('int_ventes_logement') }}
    where est_prix_plausible
)

select
    code_commune || '-' || annee || '-' || type_local        as cle,
    code_commune,
    any_value(nom_commune)                                   as nom_commune,
    any_value(code_departement)                              as code_departement,
    annee,
    type_local,
    count(*)                                                 as nb_ventes,
    round(median(prix_m2), 0)                                as prix_m2_median,
    round(quantile_cont(prix_m2, 0.25), 0)                   as prix_m2_q1,
    round(quantile_cont(prix_m2, 0.75), 0)                   as prix_m2_q3,
    round(median(valeur_fonciere), 0)                        as prix_median,
    round(median(surface_reelle_bati), 1)                    as surface_mediane,
    count(*) >= 5                                            as est_fiable
from ventes
group by code_commune, annee, type_local
