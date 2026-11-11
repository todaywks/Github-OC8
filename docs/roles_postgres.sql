-- Compte en lecture seule pour les data scientists
create role ds_reader login password 'A_DEFINIR';
grant connect on database meteo to ds_reader;
grant usage on schema marts to ds_reader;
grant select on all tables in schema marts to ds_reader;
-- dbt recrée les tables à chaque exécution : ce droit par défaut conserve la lecture
alter default privileges for role greenandcoop in schema marts grant select on tables to ds_reader;