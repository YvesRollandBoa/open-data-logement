{#- Rend la var `departements` sous forme de liste SQL : '02', '59', ... -#}
{% macro liste_departements() -%}
    {{ "'" ~ var('departements') | join("', '") ~ "'" }}
{%- endmacro %}
