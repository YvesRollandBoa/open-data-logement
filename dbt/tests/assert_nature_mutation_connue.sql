-- Échoue si la DGFiP introduit une nature de mutation inconnue (à intégrer aux règles métier).
-- Test singulier plutôt qu'accepted_values : les libellés contiennent des apostrophes.
select nature_mutation, count(*) as nb_lignes
from {{ ref('stg_dvf_mutations') }}
where nature_mutation not in (
    'Vente',
    'Vente en l''état futur d''achèvement',
    'Vente terrain à bâtir',
    'Adjudication',
    'Expropriation',
    'Echange'
)
group by nature_mutation
