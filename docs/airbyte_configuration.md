# Configuration d'Airbyte

## Installation

- Version d'Airbyte : 2.4.0
- Outil : abctl, commande d'installation : `abctl local install`
- Interface : http://localhost:8000
- Les identifiants s'obtiennent avec `abctl local credentials`

## Sources

Connecteur utilisé : File, Storage Provider HTTPS (Public Web).

| Source | Dataset | Format | URL |
|---|---|---|---|
| infoclimat | infoclimat | JSON | https://s3.eu-west-1.amazonaws.com/course.oc-static.com/projects/922_Data+Engineer/922_P8/Data_Source1_011024-071024.json |
| wu_ichtegem | wu_ichtegem | Excel | https://s3.eu-west-1.amazonaws.com/course.oc-static.com/projects/922_Data+Engineer/922_P8/Weather+Underground+-+Ichtegem%2C+BE.xlsx |
| wu_la_madeleine | wu_la_madeleine | Excel | https://s3.eu-west-1.amazonaws.com/course.oc-static.com/projects/922_Data+Engineer/922_P8/Weather+Underground+-+La+Madeleine%2C+FR.xlsx |

## Destination

| Paramètre | Valeur |
|---|---|
| Type | PostgreSQL |
| Hôte | host.docker.internal |
| Port | 5432 |
| Base | meteo |
| Schéma par défaut | raw |
| Utilisateur | greenandcoop |
| SSL | désactivé (local) |

## Connexions

| Connexion | Mode de synchronisation | Fréquence | Namespace | Préfixe |
|---|---|---|---|---|
| infoclimat vers postgres | Full refresh, écrasement | manuelle | destination | aucun |
| wu_ichtegem vers postgres | Full refresh, écrasement | manuelle | destination | aucun |
| wu_la_madeleine vers postgres | Full refresh, écrasement | manuelle | destination | aucun |

Justification : les sources sont des fichiers statiques, donc Full refresh écrasement
évite les doublons. En production, avec des flux réguliers, on passerait en incrémental
avec une planification automatique.

## Résultat de la première synchronisation

| Table | Lignes chargées | Durée | Statut |
|---|---|---|---|
| raw.infoclimat | 1 (objet JSON imbriqué contenant 1143 mesures) | 43s | succeeded |
| raw.wu_ichtegem | 1899 | 1m37s | succeeded |
| raw.wu_la_madeleine | 1908 | 1m28s | succeeded |

## Problèmes rencontrés et solutions

| Problème | Cause | Solution |
|---|---|---|
| Table JSON nommée d'après le fichier | nom du dataset par défaut | renommer le dataset en `infoclimat` |
| Connexion à Postgres impossible depuis Airbyte | `localhost` pointe vers le conteneur d'Airbyte | utiliser `host.docker.internal` |

## Observations pour la suite

- Le JSON InfoClimat arrive en une ligne avec des colonnes jsonb, à déplier avec dbt.
- Les colonnes Weather Underground sont presque toutes en texte avec leurs unités.

## Captures d'écran

Voir `docs/img/` : sources, destination, connexions et synchronisations réussies.