/*
  Dimension commune : une ligne par commune du périmètre.

  - Attributs INSEE (population, niveau de vie, parc de logements) : photo 2023.
  - Coordonnées : point central calculé à partir des ventes DVF géolocalisées
    (médiane des latitudes / longitudes), pour placer les communes sur une carte.
  - Communes « historiques » : codes présents dans DVF ou les DPE mais disparus du
    référentiel INSEE 2026 (fusions de communes). On les garde pour que les faits
    restent rattachés à une commune, avec `est_commune_historique = true`.
*/
with insee as (
    select *
    from {{ ref('int_insee_commune') }}
    where code_departement in ({{ liste_departements() }})
),

coordonnees as (
    select
        code_commune,
        round(median(latitude), 5)  as latitude,
        round(median(longitude), 5) as longitude
    from {{ ref('stg_dvf_mutations') }}
    where latitude is not null and longitude is not null
    group by code_commune
),

codes_faits as (
    select code_commune, nom_commune, code_departement from {{ ref('stg_dvf_mutations') }}
    union all
    select code_commune, nom_commune, code_departement from {{ ref('stg_dpe_logements') }}
),

historiques as (
    select
        code_commune,
        any_value(nom_commune)      as nom_commune,
        any_value(code_departement) as code_departement
    from codes_faits
    where code_departement in ({{ liste_departements() }})
      and code_commune not in (select code_commune from insee)
    group by code_commune
),

communes as (
    select code_commune, nom_commune, code_departement, false as est_commune_historique from insee
    union all
    select code_commune, nom_commune, code_departement, true from historiques
)

select
    c.code_commune,
    c.nom_commune,
    c.nom_commune || ' (' || c.code_departement || ')'                    as nom_commune_dep,
    c.code_departement,
    d.nom_departement,
    d.nom_region,
    c.est_commune_historique,
    xy.latitude,
    xy.longitude,
    i.population,
    i.superficie_km2,
    round(i.population / nullif(i.superficie_km2, 0), 1)                 as densite_hab_km2,
    case
        when i.population is null then null
        when i.population < 2000   then '1. Moins de 2 000 hab.'
        when i.population < 10000  then '2. 2 000 à 10 000 hab.'
        when i.population < 50000  then '3. 10 000 à 50 000 hab.'
        else '4. Plus de 50 000 hab.'
    end                                                                   as taille_commune,
    i.niveau_vie_median,
    i.niveau_vie_sous_secret,
    i.taux_pauvrete,
    -- effectifs INSEE pondérés (décimaux dans la source) : arrondis
    round(i.nb_logements)::integer                                    as nb_logements,
    round(i.nb_residences_principales)::integer                       as nb_residences_principales,
    round(i.nb_logements_vacants)::integer                            as nb_logements_vacants,
    round(i.nb_residences_secondaires)::integer                       as nb_residences_secondaires,
    round(i.nb_proprietaires)::integer                                as nb_proprietaires
from communes c
left join {{ ref('departements') }} d using (code_departement)
left join coordonnees xy using (code_commune)
left join {{ ref('int_insee_commune') }} i using (code_commune)
