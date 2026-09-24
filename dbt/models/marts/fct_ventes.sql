/*
  Fait « vente » : une ligne par vente d'un logement, au grain le plus fin.

  On exporte le détail (et non des médianes précalculées) car une médiane ne
  s'additionne pas : Power BI la recalcule avec MEDIANX selon les filtres actifs
  (période, commune, type…). Seules les ventes au prix plausible sont gardées.

  Relations Power BI :
    fct_ventes[date_vente]   → dim_date[date]
    fct_ventes[code_commune] → dim_commune[code_commune]
*/
select
    id_mutation,
    date_mutation                    as date_vente,
    code_commune,
    type_local                       as type_logement,
    surface_reelle_bati              as surface_m2,
    nombre_pieces_principales        as nb_pieces,
    valeur_fonciere                  as prix,
    prix_m2,
    latitude,
    longitude
from {{ ref('int_ventes_logement') }}
where est_prix_plausible
  and code_departement in ({{ liste_departements() }})
