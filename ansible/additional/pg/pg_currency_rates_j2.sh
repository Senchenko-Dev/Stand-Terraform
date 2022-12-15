#!/usr/bin/env bash

# todo имя БД, схемы и пользователя  лучше параметрировать через {{ db_name }}, {{ schema_name }},  {{ tablespace_location }}
# todo НО!!! {{ schema_name }} - это общее. а надо в этом файле указать. Через export SCHEMA_NAME= и $SCHEMA_NAME  ?? << EOF
# todo tablespace_name
# todo tablespace_location
# todo db_name
# todo schema_name

mkdir -p {{ tablespace_location }}/{{ schema_name }}_i
mkdir -p {{ tablespace_location }}/{{ schema_name }}_t
chown -R postgres:postgres {{ tablespace_location }}/{{ schema_name }}_i
chown -R postgres:postgres {{ tablespace_location }}/{{ schema_name }}_t
chmod 700 {{ tablespace_location }}/{{ schema_name }}_i
chmod 700 {{ tablespace_location }}/{{ schema_name }}_t

# todo это лучше параметрировать через {{ db_name }}

sudo -i -u postgres bash << EOF
export PGDATABASE=test_db
psql -c "create user currency_rates with encrypted password 'StrongUserPassword720!';"
psql -c "create user currency_rates_appl with encrypted password 'StrongUserPassword720!';"
psql -c "GRANT \"as_TUZ\" TO currency_rates;"
psql -c "GRANT \"as_TUZ\" TO currency_rates_appl;"
psql -c "GRANT USAGE ON SCHEMA currency_rates TO \"as_TUZ\";"
psql -c "GRANT USAGE ON SCHEMA currency_rates TO as_admin_read;"
psql -c "GRANT ALL ON SCHEMA currency_rates TO currency_rates;"
psql -c "GRANT ALL ON SCHEMA currency_rates TO db_admin;"

# ------ todo это лучше параметрировать через {{ db_name }}  или задать заранее PGDATABASE
psql test_db -c "create schema currency_rates AUTHORIZATION currency_rates;"

psql -c "grant connect on database postgres to currency_rates;"
psql -c "grant all on schema currency_rates to currency_rates;"
psql -c "alter user currency_rates VALID UNTIL 'infinity';"
psql -c "grant usage on schema currency_rates to currency_rates;"
psql -c "create tablespace {{ schema_name }}_t owner currency_rates location '{{ tablespace_location }}/{{ schema_name }}_t';"
psql -c "create tablespace {{ schema_name }}_i owner currency_rates location '{{ tablespace_location }}/{{ schema_name }}_i';"
psql -c "ALTER TABLESPACE {{ schema_name }}_t OWNER TO currency_rates;"
psql -c "ALTER TABLESPACE {{ schema_name }}_i OWNER TO currency_rates;"
psql -c "GRANT CREATE ON TABLESPACE {{ schema_name }}_t TO currency_rates;"
psql -c "GRANT CREATE ON TABLESPACE {{ schema_name }}_i TO currency_rates;"
psql -c "GRANT ALL ON TABLESPACE {{ schema_name }}_t TO currency_rates;"
psql -c "GRANT ALL ON TABLESPACE {{ schema_name }}_i TO currency_rates;"
psql -c "alter default privileges in schema currency_rates grant ALL on tables to currency_rates;"
psql -c "grant select on all sequences in schema currency_rates to currency_rates;"
psql -c "grant all privileges on all tables in schema currency_rates to currency_rates;"
psql -c "grant select on all tables in schema currency_rates to currency_rates;"
psql -c "ALTER ROLE currency_rates SET search_path = currency_rates;"
psql -c "ALTER ROLE currency_rates_appl SET search_path = currency_rates;"

psql -c "CREATE SCHEMA ekpit AUTHORIZATION db_admin;"

EOF

