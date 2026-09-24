-- Toutes les parts (ratios) du mart communal doivent être comprises entre 0 et 1.
select code_commune, nom_commune
from {{ ref('mart_logement_commune') }}
where part_logements_vacants      not between 0 and 1
   or part_residences_secondaires not between 0 and 1
   or part_proprietaires          not between 0 and 1
   or part_passoires_thermiques   not between 0 and 1
   or part_logements_performants  not between 0 and 1
