#!/usr/bin/env bash

# todo имя БД, схемы и пользователя  лучше параметрировать через {{ db_name }}, {{  }}, {{  }}
# todo tablespace_name
# todo tablespace_location
# todo db_name
# todo schema_name

mkdir -p /pgdata/pg_tblspc/currency_rates_i
mkdir -p /pgdata/pg_tblspc/currency_rates_t
chown -R postgres:postgres /pgdata/pg_tblspc/currency_rates_i
chown -R postgres:postgres /pgdata/pg_tblspc/currency_rates_t
chmod 700 /pgdata/pg_tblspc/currency_rates_i
chmod 700 /pgdata/pg_tblspc/currency_rates_t

# todo это лучше параметрировать через {{ db_name }}
export PGDATABASE=test_db

sudo -i -u postgres bash << EOF
export PGDATABASE=test_db

psql -c "create user currency_rates with encrypted password 'StrongUserAdminPassword720!';"
psql -c "create user currency_rates_appl with encrypted password 'StrongUserAdminPassword720!';"
psql -c "GRANT \"as_TUZ\" TO currency_rates;"
psql -c "GRANT \"as_TUZ\" TO currency_rates_appl;"
psql -c "GRANT USAGE ON SCHEMA currency_rates TO \"as_TUZ\";"
psql -c "GRANT USAGE ON SCHEMA currency_rates TO as_admin_read;"
psql -c "GRANT ALL ON SCHEMA currency_rates TO currency_rates;"
psql -c "GRANT ALL ON SCHEMA currency_rates TO db_admin;"

# ------ todo это лучше параметрировать через {{ db_name }}  или задать заранее PGDATABASE
psql -c "create schema currency_rates AUTHORIZATION currency_rates;"

psql -c "grant connect on database postgres to currency_rates;"
psql -c "grant all on schema currency_rates to currency_rates;"
psql -c "alter user currency_rates VALID UNTIL 'infinity';"
psql -c "grant usage on schema currency_rates to currency_rates;"
psql -c "create tablespace currency_rates_t owner currency_rates location '/pgdata/pg_tblspc/currency_rates_t';"
psql -c "create tablespace currency_rates_i owner currency_rates location '/pgdata/pg_tblspc/currency_rates_i';"
psql -c "ALTER TABLESPACE currency_rates_t OWNER TO currency_rates;"
psql -c "ALTER TABLESPACE currency_rates_i OWNER TO currency_rates;"
psql -c "GRANT CREATE ON TABLESPACE currency_rates_t TO currency_rates;"
psql -c "GRANT CREATE ON TABLESPACE currency_rates_i TO currency_rates;"
psql -c "GRANT ALL ON TABLESPACE currency_rates_t TO currency_rates;"
psql -c "GRANT ALL ON TABLESPACE currency_rates_i TO currency_rates;"
psql -c "alter default privileges in schema currency_rates grant ALL on tables to currency_rates;"
psql -c "grant select on all sequences in schema currency_rates to currency_rates;"
psql -c "grant all privileges on all tables in schema currency_rates to currency_rates;"
psql -c "grant select on all tables in schema currency_rates to currency_rates;"
psql -c "ALTER ROLE currency_rates SET search_path = currency_rates;"
psql -c "ALTER ROLE currency_rates_appl SET search_path = currency_rates;"

psql -c "CREATE SCHEMA ekpit AUTHORIZATION db_admin;"

EOF

