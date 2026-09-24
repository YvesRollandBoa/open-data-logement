-- Échoue si une médiane sort des bornes de plausibilité : signe d'un filtre cassé en amont.
select *
from {{ ref('mart_prix_commune_annee') }}
where prix_m2_median not between 200 and 30000
