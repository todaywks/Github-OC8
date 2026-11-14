# Airbyte : collecte des données

Airbyte copie les trois fichiers sources dans le schéma `raw` de PostgreSQL, sans les modifier. Toute la transformation est faite ensuite par dbt.

## Vue d'ensemble

| Élément | Valeur |
|---|---|
| Source | connecteur File, fournisseur HTTPS (URL publiques) |
| Destination | PostgreSQL, base `meteo`, schéma `raw` |
| Connexions | 3, une par fichier |
| Mode de synchronisation | full refresh, avec écrasement (overwrite) |
| Fréquence | manuelle, les fichiers sources étant figés |

## Les trois connexions

| Connexion | Format | Table créée dans `raw` | Contenu |
|---|---|---|---|
| infoclimat | JSON | `infoclimat` | une ligne, tout le JSON dans des colonnes `jsonb` |
| wu_ichtegem | CSV | `wu_ichtegem` | relevés de la station d'Ichtegem (Belgique) |
| wu_la_madeleine | CSV | `wu_la_madeleine` | relevés de la station de La Madeleine (France) |

Adresses des fichiers (à renseigner) :

- InfoClimat : `https://s3.eu-west-1.amazonaws.com/course.oc-static.com/projects/922_Data+Engineer/922_P8/Data_Source1_011024-071024.json`
- Weather Underground, Ichtegem : `https://raw.githubusercontent.com/todaywks/Github-OC8/main/data/wu_ichtegem_be.csv`
- Weather Underground, La Madeleine : `https://raw.githubusercontent.com/todaywks/Github-OC8/main/data/wu_la_madeleine_fr.csv`

Les adresses doivent pointer vers le fichier brut (`raw.githubusercontent.com` pour un fichier hébergé sur GitHub), et non vers la page web du fichier (adresse contenant `/blob/`).

Le nom du jeu de données (dataset) de chaque source donne le nom de la table dans `raw`. Pour renommer une table, il faut changer ce nom dans la source, relancer la synchronisation et supprimer l'ancienne table.

## Classeurs Excel : étape préalable

Les deux fichiers Weather Underground sont des classeurs de 7 onglets, un par jour, et la date n'existe que dans le nom de l'onglet. Airbyte empile les onglets sans conserver ce nom, ce qui ferait perdre les dates.

Le script `scripts/flatten_workbooks.py` lit chaque onglet (en texte, sans conversion) et ajoute une colonne `sheet_name` avec le nom de l'onglet. Les fichiers CSV obtenus sont ceux qu'Airbyte charge.

```bash
python scripts/flatten_workbooks.py data/*.xlsx
```

## Destination PostgreSQL

| Paramètre | Local | AWS |
|---|---|---|
| Hôte | `host.docker.internal` | point de terminaison de l'instance RDS |
| Port | 5432 | 5432 |
| Base | `meteo` | `meteo` |
| Schéma | `raw` | `raw` |
| Option avancée | Drop tables with CASCADE | Drop tables with CASCADE |

En local, Airbyte tourne dans son propre cluster : `localhost` y désignerait le conteneur d'Airbyte et non la base. Il faut donc utiliser `host.docker.internal`.

### L'option Drop tables with CASCADE

Les vues dbt de la couche `staging` lisent les tables de `raw`. En mode écrasement, Airbyte doit remplacer ces tables, et PostgreSQL refuse de supprimer une table dont des vues dépendent. L'option CASCADE lève ce blocage, mais elle supprime aussi les vues.

**Conséquence : il faut relancer `dbt build` après chaque synchronisation** pour recréer `staging` et le reste des modèles.

## Installation locale

Airbyte s'installe avec `abctl`, l'outil officiel, qui crée un petit cluster Kubernetes dans un conteneur Docker.

```bash
abctl local install
abctl local credentials
```

L'interface s'ouvre sur `http://localhost:8000`.

## Installation sur AWS

Airbyte est installé sur une instance EC2 `m7i-flex.large` (Amazon Linux 2023, disque de 30 Go) avec le même outil, en mode économe en ressources, et 4 Go d'espace d'échange (swap).

L'interface n'est pas exposée sur Internet. On y accède par un tunnel SSH depuis l'ordinateur :

```bash
ssh -i <cle>.pem -L 8001:localhost:8000 ec2-user@<adresse de l'instance>
```

L'interface est alors disponible sur `http://localhost:8001`, tant que le terminal reste ouvert.

La configuration (source, destination, trois connexions) est recréée dans cette instance, avec l'hôte de la destination remplacé par celui de RDS.

## Supervision

Les journaux d'Airbyte sont envoyés dans CloudWatch (groupe `/airbyte/meteo`, conservés 14 jours) par l'agent CloudWatch installé sur l'instance, qui envoie aussi la mémoire, le swap et l'espace disque (espace de noms `Airbyte/EC2`). Une alarme prévient quand le disque dépasse 85 %.

Pour retrouver la fin d'une synchronisation, interroger le groupe `/airbyte/meteo` avec CloudWatch Logs Insights.

Référence : la synchronisation des 1915 lignes de La Madeleine (environ 477 Ko) dure 26 secondes.

## Points d'attention

| Symptôme | Cause | Solution |
|---|---|---|
| Airbyte n'atteint pas la base | `localhost` désigne le conteneur d'Airbyte | utiliser `host.docker.internal` en local |
| Airbyte ne lit pas l'URL GitHub | l'adresse contient `/blob/` | utiliser l'adresse `raw.githubusercontent.com` |
| HTTPS introuvable parmi les connecteurs | c'est une option du connecteur File | choisir File, puis le fournisseur HTTPS |
| Les heures se répètent, les dates manquent | les onglets Excel sont empilés sans leur nom | passer par `scripts/flatten_workbooks.py` |
| Date fausse après conversion de `sheet_name` | un nom comme 011024 est lu comme un nombre, le zéro initial disparaît | rétablir le zéro avec `lpad` dans dbt |
| Les vues staging ont disparu après une synchronisation | effet de l'option CASCADE | relancer `dbt build` |