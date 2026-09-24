/*
  Table centrale du dashboard : une ligne par commune du périmètre.

  Croise trois sources par le code commune INSEE :
    - INSEE : population, niveau de vie, structure du parc de logements ;
    - DVF   : prix de l'immobilier sur les années récentes (var `annees_recentes`) ;
    - DPE   : performance énergétique des logements diagnostiqués.

  Indicateur phare — `annees_niveau_vie_pour_acheter` :
    prix médian d'un logement / niveau de vie médian annuel de la commune.
  Le niveau de vie est un revenu par « unité de consommation » : l'indicateur
  sert à comparer les communes entre elles, pas à mesurer un effort réel de ménage.
*/
{% set annees = var('annees_recentes') %}

with communes as (
    select *
    from {{ ref('int_insee_commune') }}
    where code_departement in ({{ liste_departements() }})
),

ventes as (
    select
        code_commune,
        count(*)                                                                 as nb_ventes,
        count(*) filter (where type_local = 'Appartement')                       as nb_ventes_appartement,
        count(*) filter (where type_local = 'Maison')                            as nb_ventes_maison,
        round(median(prix_m2) filter (where type_local = 'Appartement'), 0)      as prix_m2_median_appartement,
        round(median(prix_m2) filter (where type_local = 'Maison'), 0)           as prix_m2_median_maison,
        round(median(valeur_fonciere), 0)                                        as prix_median_logement,
        round(median(surface_reelle_bati), 1)                                    as surface_mediane_vendue
    from {{ ref('int_ventes_logement') }}
    where est_prix_plausible
      and annee in ({{ annees | join(', ') }})
    group by code_commune
),

dpe as (
    select
        code_commune,
        count(*)                                                    as nb_logements_diagnostiques,
        avg(est_passoire_thermique::int)                            as part_passoires_thermiques,
        avg(est_logement_performant::int)                           as part_logements_performants,
        round(median(conso_energie_primaire_m2), 0)                 as conso_energie_mediane_m2,
        mode(etiquette_dpe)                                         as etiquette_dpe_la_plus_frequente
    from {{ ref('int_dpe_logement_dernier') }}
    group by code_commune
)

select
    c.code_commune,
    c.nom_commune,
    c.code_departement,

    -- Démographie & revenus (INSEE)
    c.population,
    c.superficie_km2,
    round(c.population / nullif(c.superficie_km2, 0), 1)                         as densite_hab_km2,
    c.niveau_vie_median,
    c.niveau_vie_sous_secret,
    c.taux_pauvrete,

    -- Parc de logements (INSEE)
    c.nb_logements,
    round(c.nb_logements_vacants / nullif(c.nb_logements, 0), 4)                 as part_logements_vacants,
    round(c.nb_residences_secondaires / nullif(c.nb_logements, 0), 4)            as part_residences_secondaires,
    round(c.nb_proprietaires / nullif(c.nb_residences_principales, 0), 4)        as part_proprietaires,

    -- Marché immobilier (DVF, années récentes)
    coalesce(v.nb_ventes, 0)                                                     as nb_ventes,
    v.nb_ventes_appartement,
    v.nb_ventes_maison,
    v.prix_m2_median_appartement,
    v.prix_m2_median_maison,
    v.prix_median_logement,
    v.surface_mediane_vendue,
    coalesce(v.nb_ventes, 0) >= 10                                               as prix_est_fiable,

    -- Accessibilité
    round(v.prix_median_logement / nullif(c.niveau_vie_median, 0), 1)            as annees_niveau_vie_pour_acheter,

    -- Performance énergétique (DPE)
    coalesce(d.nb_logements_diagnostiques, 0)                                    as nb_logements_diagnostiques,
    round(d.part_passoires_thermiques, 4)                                        as part_passoires_thermiques,
    round(d.part_logements_performants, 4)                                       as part_logements_performants,
    d.conso_energie_mediane_m2,
    d.etiquette_dpe_la_plus_frequente,
    coalesce(d.nb_logements_diagnostiques, 0) >= 20                              as dpe_est_fiable,

    '{{ annees | first }}-{{ annees | last }}'                                   as periode_dvf
from communes c
left join ventes v using (code_commune)
left join dpe d using (code_commune)
