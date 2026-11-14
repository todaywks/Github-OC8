# Airbyte : collecte des données

Airbyte copie les trois fichiers sources dans le schéma `raw` de PostgreSQL, sans les modifier. Toute la transformation est faite ensuite par dbt.

## Vue d'ensemble

| Élément | Valeur |
|---|---|
| Version | Airbyte 2.4.0, installé avec `abctl` |
| Source | connecteur File, fournisseur HTTPS (Public Web) |
| Destination | PostgreSQL, base `meteo`, schéma `raw` |
| Connexions | 3, une par fichier |
| Mode de synchronisation | full refresh, avec écrasement (overwrite) |
| Fréquence | manuelle, les fichiers sources étant figés |

## Installation locale

```bash
abctl local install
abctl local credentials
```

L'interface est disponible sur `http://localhost:8000`. La seconde commande affiche les identifiants de connexion.

`abctl` crée un petit cluster Kubernetes dans un conteneur Docker. L'installation se trouve dans le dossier personnel de l'utilisateur, pas dans ce dépôt.

## Sources

Connecteur utilisé : File, Storage Provider HTTPS (Public Web).

| Source | Dataset | Format | URL |
|---|---|---|---|
| infoclimat | infoclimat | JSON | https://s3.eu-west-1.amazonaws.com/course.oc-static.com/projects/922_Data+Engineer/922_P8/Data_Source1_011024-071024.json |
| github-wu_ichtegem | wu_ichtegem | csv | https://raw.githubusercontent.com/todaywks/Github-OC8/main/data/wu_ichtegem_be.csv |
| github-wu_la_madeleine | wu_la_madeleine | csv | https://raw.githubusercontent.com/todaywks/Github-OC8/main/data/wu_la_madeleine_fr.csv |

Le nom du dataset donne le nom de la table dans `raw`. Pour renommer une table, il faut changer ce nom dans la source, relancer la synchronisation et supprimer l'ancienne table.

Les adresses doivent pointer vers le fichier brut (`raw.githubusercontent.com` pour un fichier hébergé sur GitHub), et non vers la page web du fichier (adresse contenant `/blob/`).

### Classeurs Excel : étape préalable

Les deux fichiers Weather Underground sont des classeurs de 7 onglets, un par jour, et la date n'existe que dans le nom de l'onglet. Airbyte empile les onglets sans conserver ce nom, ce qui ferait perdre les dates.

Le script `scripts/flatten_workbooks.py` lit chaque onglet (en texte, sans conversion) et ajoute une colonne `sheet_name` avec le nom de l'onglet. Ce sont les fichiers CSV obtenus qu'Airbyte charge.

```bash
python scripts/flatten_workbooks.py data/*.xlsx
```

## Destination

| Paramètre | Local | AWS |
|---|---|---|
| Type | PostgreSQL | PostgreSQL (RDS) |
| Hôte | `host.docker.internal` | point de terminaison de l'instance RDS |
| Port | 5432 | 5432 |
| Base | `meteo` | `meteo` |
| Schéma par défaut | `raw` | `raw` |
| Utilisateur | `greenandcoop` | `greenandcoop` |
| SSL | désactivé | selon la configuration de RDS |
| Option avancée | Drop tables with CASCADE | Drop tables with CASCADE |

En local, Airbyte tourne dans son propre cluster : `localhost` y désignerait le conteneur d'Airbyte et non la base. Il faut donc utiliser `host.docker.internal`.

### L'option Drop tables with CASCADE

Les vues dbt de la couche `staging` lisent les tables de `raw`. En mode écrasement, Airbyte doit remplacer ces tables, et PostgreSQL refuse de supprimer une table dont des vues dépendent. L'option CASCADE lève ce blocage, mais elle supprime aussi les vues.

**Conséquence : il faut relancer `dbt build` après chaque synchronisation** pour recréer `staging` et le reste des modèles.

## Connexions

| Connexion | Mode de synchronisation | Fréquence | Namespace | Préfixe |
|---|---|---|---|---|
| infoclimat vers postgres | Full refresh, écrasement | manuelle | destination | aucun |
| wu_ichtegem vers postgres | Full refresh, écrasement | manuelle | destination | aucun |
| wu_la_madeleine vers postgres | Full refresh, écrasement | manuelle | destination | aucun |

Justification : les sources sont des fichiers statiques, donc le full refresh avec écrasement évite les doublons. Avec des flux réguliers, on passerait en incrémental avec une planification automatique.

## Résultat de la première synchronisation (en local)

| Table | Lignes chargées | Durée | Statut |
|---|---|---|---|
| raw.infoclimat | 1 (objet JSON imbriqué contenant 1143 mesures) | 43 s | succeeded |
| raw.wu_ichtegem | 1906, dont 7 lignes vides (une par onglet) | 1 min 37 s | succeeded |
| raw.wu_la_madeleine | 1915, dont 7 lignes vides (une par onglet) | 1 min 28 s | succeeded |

Les lignes vides sont conservées dans `raw` et écartées par dbt en `staging` : il reste 1899 et 1908 mesures.

Sur AWS, la synchronisation des 1915 lignes de La Madeleine (environ 477 Ko) dure 26 secondes.

## Installation sur AWS

Airbyte est installé sur une instance EC2 `m7i-flex.large` (Amazon Linux 2023, disque de 30 Go) avec `abctl`, en mode économe en ressources, et 4 Go d'espace d'échange (swap).

L'interface n'est pas exposée sur Internet. On y accède par un tunnel SSH depuis l'ordinateur :

```bash
ssh -i <cle>.pem -L 8001:localhost:8000 ec2-user@<adresse de l'instance>
```

L'interface est alors disponible sur `http://localhost:8001`, tant que le terminal reste ouvert.

La configuration (sources, destination, trois connexions) est recréée dans cette instance, avec l'hôte de la destination remplacé par celui de RDS.

## Supervision sur AWS

Les journaux d'Airbyte sont envoyés dans CloudWatch (groupe `/airbyte/meteo`, conservés 14 jours) par l'agent CloudWatch installé sur l'instance. Il envoie aussi la mémoire, le swap et l'espace disque (espace de noms `Airbyte/EC2`). Une alarme prévient quand le disque dépasse 85 %.

Pour retrouver la fin d'une synchronisation, interroger le groupe `/airbyte/meteo` avec CloudWatch Logs Insights.

## Problèmes rencontrés et solutions

| Problème | Cause | Solution |
|---|---|---|
| Table JSON nommée d'après le fichier | nom du dataset par défaut | renommer le dataset en `infoclimat` |
| Connexion à Postgres impossible depuis Airbyte | `localhost` pointe vers le conteneur d'Airbyte | utiliser `host.docker.internal` |
| Airbyte ne lit pas l'URL GitHub | l'adresse contient `/blob/` | utiliser l'adresse `raw.githubusercontent.com` |
| HTTPS introuvable parmi les connecteurs | c'est une option du connecteur File | choisir File, puis le fournisseur HTTPS |
| Les heures se répètent, les dates manquent | les onglets Excel sont empilés sans leur nom | passer par `scripts/flatten_workbooks.py` |
| Date fausse après conversion de `sheet_name` | un nom comme 011024 est lu comme un nombre, le zéro initial disparaît | rétablir le zéro avec `lpad` dans dbt |
| Les vues staging ont disparu après une synchronisation | effet de l'option CASCADE | relancer `dbt build` |

## Observations pour la suite

- Le JSON InfoClimat arrive en une ligne avec des colonnes `jsonb`, à déplier avec dbt.
- Les colonnes Weather Underground sont presque toutes en texte, avec leurs unités.

## Captures d'écran

Voir `docs/img/` : sources, destination, connexions et synchronisations réussies.