/*
  Un logement = son DPE le plus récent.

  Le DPE n'a pas d'identifiant de logement : un même logement rediagnostiqué
  (vente puis location, correction…) apparaît plusieurs fois. Dans l'Aisne,
  ~30 % des DPE sont ainsi des doublons. On reconstruit une clé logement :
    adresse BAN + type + surface arrondie
  (plusieurs appartements partagent la même adresse ; la surface les distingue).

  Les DPE « immeuble » (bâtiment entier) sont exclus : ils décrivent un ensemble
  de logements et fausseraient les parts calculées par logement.

  Limite : seuls les logements diagnostiqués depuis juillet 2021 (vente, location)
  sont présents — c'est un échantillon du parc, pas le parc entier.
*/
with dpe as (
    select *
    from {{ ref('stg_dpe_logements') }}
    where type_batiment in ('maison', 'appartement')
      and code_commune is not null
),

avec_cle as (
    select
        *,
        coalesce(identifiant_ban, 'sans-adresse-' || numero_dpe)
            || '|' || type_batiment
            || '|' || coalesce(cast(round(surface_habitable) as varchar), '?') as cle_logement
    from dpe
)

select
    cle_logement,
    numero_dpe,
    date_etablissement_dpe,
    code_commune,
    nom_commune,
    code_departement,
    type_batiment,
    periode_construction,
    annee_construction,
    surface_habitable,
    etiquette_dpe,
    etiquette_ges,
    conso_energie_primaire_m2,
    emission_ges_m2,
    etiquette_dpe in ('F', 'G') as est_passoire_thermique,
    etiquette_dpe in ('A', 'B') as est_logement_performant
from avec_cle
qualify row_number() over (
    partition by cle_logement
    order by date_etablissement_dpe desc, numero_dpe desc
) = 1
