/*
  Table de dates (une ligne par jour) pour l'intelligence temporelle Power BI.
  Couvre du 1er janvier 2021 au 31 décembre de l'année en cours.
  À marquer comme « table de dates » dans Power BI (colonne `date`).
*/
with jours as (
    select cast(d as date) as date
    from generate_series(
        date '2021-01-01',
        cast(date_trunc('year', current_date) + interval 1 year - interval 1 day as date),
        interval 1 day
    ) as t(d)
),

libelles as (
    select
        ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
         'août', 'septembre', 'octobre', 'novembre', 'décembre']                 as mois_fr,
        ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.',
         'août', 'sept.', 'oct.', 'nov.', 'déc.']                                as mois_courts_fr,
        ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'] as jours_fr
)

select
    date,
    year(date)                                              as annee,
    case when month(date) <= 6 then 1 else 2 end            as semestre,
    year(date) || '-S' || case when month(date) <= 6 then 1 else 2 end as annee_semestre,
    quarter(date)                                           as trimestre,
    year(date) || '-T' || quarter(date)                     as annee_trimestre,
    month(date)                                             as mois,
    mois_fr[month(date)]                                    as nom_mois,
    mois_courts_fr[month(date)]                             as nom_mois_court,
    strftime(date, '%Y-%m')                                 as annee_mois,
    -- clé de tri pour afficher « janv. 2024 » dans l'ordre chronologique
    year(date) * 100 + month(date)                          as annee_mois_tri,
    cast(date_trunc('month', date) as date)                 as premier_jour_mois,
    isodow(date)                                            as jour_semaine,
    jours_fr[isodow(date)]                                  as nom_jour,
    isodow(date) >= 6                                       as est_weekend
from jours, libelles
