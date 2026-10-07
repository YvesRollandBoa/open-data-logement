/*
  Fait « DPE réalisés » agrégé au mois : commune × mois × type × période de construction × étiquette.

  Ce sont des flux (diagnostics réalisés dans le mois), pas le parc : un logement
  rediagnostiqué compte à chaque diagnostic. Pour une photo du parc, voir
  mart_logement_commune (un logement = son dernier DPE).

  Les comptages sont additifs : la part de passoires (F+G / total) reste juste
  quel que soit le filtre appliqué dans Power BI.

  Relations Power BI :
    fct_dpe_mensuel[mois]         → dim_date[date]   (1er jour du mois)
    fct_dpe_mensuel[code_commune] → dim_commune[code_commune]
*/
with dpe as (
    select *
    from {{ ref('stg_dpe_logements') }}
    where type_batiment in ('maison', 'appartement')
      and code_departement in ({{ liste_departements() }})
      and date_etablissement_dpe is not null
)

select
    cast(date_trunc('month', date_etablissement_dpe) as date)         as mois,
    code_commune,
    type_batiment                                                      as type_logement,
    coalesce(periode_construction, 'inconnue')                         as periode_construction,
    -- ordre chronologique des périodes (« Trier par colonne » dans Power BI)
        {{ periode_construction_tri("periode_construction") }}              as periode_construction_tri,
    etiquette_dpe,
    etiquette_dpe in ('F', 'G')                                        as est_passoire_thermique,
    count(*)                                                           as nb_dpe,
    round(sum(surface_habitable), 1)                                   as surface_totale_m2
from dpe
group by all
