{#- Utilise le nom de schéma tel quel (staging, intermediate, marts)
    au lieu du préfixe par défaut de dbt (main_staging, …). -#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}{{ target.schema }}{%- else -%}{{ custom_schema_name | trim }}{%- endif -%}
{%- endmacro %}
