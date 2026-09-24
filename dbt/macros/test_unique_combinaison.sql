{#- Test générique : la combinaison de colonnes est unique (grain de la table). -#}
{% test unique_combinaison(model, colonnes) %}
select {{ colonnes | join(', ') }}, count(*) as nb
from {{ model }}
group by {{ colonnes | join(', ') }}
having count(*) > 1
{% endtest %}
