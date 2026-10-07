{#
  Ordre chronologique des périodes de construction DPE.
  Appelée par fct_dpe_mensuel et mart_dpe_commune_etiquette,
  pour que la règle ne soit écrite qu'une seule fois.
#}
{% macro periode_construction_tri(colonne) %}
    case {{ colonne }}
        when 'avant 1948' then 1
        when '1948-1974'  then 2
        when '1975-1977'  then 3
        when '1978-1982'  then 4
        when '1983-1988'  then 5
        when '1989-2000'  then 6
        when '2001-2005'  then 7
        when '2006-2012'  then 8
        when '2013-2021'  then 9
        when 'après 2021' then 10
        else 99
    end
{% endmacro %}