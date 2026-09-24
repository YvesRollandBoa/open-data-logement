/*
  Une ligne = une vente d'UN seul logement (maison ou appartement).

  Règles (méthode proche de celle du Cerema / DVF+) :
    - nature « Vente » uniquement (hors VEFA, adjudications, échanges…) ;
    - la mutation contient exactement un logement : les ventes en bloc (immeubles,
      lots multiples) ont un prix global impossible à ramener au m² d'un logement ;
    - pas de local d'activité dans la mutation (sinon le prix mélange les usages) ;
    - le logement a une surface renseignée (sinon pas de prix au m²) ;
    - les dépendances (garage, cave…) sont tolérées : elles restent dans le prix,
      comme sur le marché réel.
  Les valeurs aberrantes sont filtrées ensuite (voir `est_prix_plausible`).
*/
with lignes as (
    select * from {{ ref('stg_dvf_mutations') }}
    where nature_mutation = 'Vente'
),

-- Un même local peut apparaître sur plusieurs lignes (plusieurs parcelles) : on dédoublonne.
locaux as (
    select distinct
        id_mutation, type_local, surface_reelle_bati, nombre_pieces_principales, lot1_numero
    from lignes
    where type_local is not null
),

profil_mutation as (
    select
        id_mutation,
        count(*) filter (where type_local in ('Maison', 'Appartement'))            as nb_logements,
        count(*) filter (where type_local = 'Local industriel. commercial ou assimilé') as nb_locaux_activite
    from locaux
    group by id_mutation
),

mutation as (
    -- valeur foncière, date et commune sont identiques sur toutes les lignes d'une mutation
    select
        id_mutation,
        any_value(date_mutation)    as date_mutation,
        any_value(annee)            as annee,
        any_value(valeur_fonciere)  as valeur_fonciere,
        any_value(code_commune)     as code_commune,
        any_value(nom_commune)      as nom_commune,
        any_value(code_departement) as code_departement,
        any_value(longitude)        as longitude,
        any_value(latitude)         as latitude
    from lignes
    group by id_mutation
),

logement as (
    select
        id_mutation,
        any_value(type_local)                as type_local,
        any_value(surface_reelle_bati)       as surface_reelle_bati,
        any_value(nombre_pieces_principales) as nombre_pieces_principales
    from locaux
    where type_local in ('Maison', 'Appartement')
    group by id_mutation
)

select
    m.id_mutation,
    m.date_mutation,
    m.annee,
    m.code_commune,
    m.nom_commune,
    m.code_departement,
    l.type_local,
    l.surface_reelle_bati,
    l.nombre_pieces_principales,
    m.valeur_fonciere,
    round(m.valeur_fonciere / nullif(l.surface_reelle_bati, 0), 2) as prix_m2,
    m.longitude,
    m.latitude,
    (
        l.surface_reelle_bati >= 9
        and m.valeur_fonciere >= 1000
        and m.valeur_fonciere / l.surface_reelle_bati between 200 and 30000
    ) as est_prix_plausible
from mutation m
join profil_mutation p using (id_mutation)
join logement l using (id_mutation)
where p.nb_logements = 1
  and p.nb_locaux_activite = 0
  -- Surface absente dans DVF (quelques dizaines de cas par an) : prix au m² incalculable.
  and l.surface_reelle_bati > 0
