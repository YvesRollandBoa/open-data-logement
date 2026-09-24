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
    case periode_construction
        when 'avant 1948' then 1  when '1948-1974' then 2  when '1975-1977' then 3
        when '1978-1982' then 4   when '1983-1988' then 5  when '1989-2000' then 6
        when '2001-2005' then 7   when '2006-2012' then 8  when '2013-2021' then 9
        when 'après 2021' then 10 else 99
    end                                                                as periode_construction_tri,
    etiquette_dpe,
    etiquette_dpe in ('F', 'G')                                        as est_passoire_thermique,
    count(*)                                                           as nb_dpe,
    round(sum(surface_habitable), 1)                                   as surface_totale_m2
from dpe
group by all
