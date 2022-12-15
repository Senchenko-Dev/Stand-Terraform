#!/usr/bin/env bash

# todo имя БД, схемы и пользователя  лучше параметрировать через {{ db_name }}, {{  }}, {{  }}
# todo tablespace_name
# todo tablespace_location
# todo db_name
# todo schema_name

mkdir -p /pgdata/pg_tblspc/uftm_bf1_i
mkdir -p /pgdata/pg_tblspc/uftm_bf1_t
chown -R postgres:postgres /pgdata/pg_tblspc/uftm_bf1_i
chown -R postgres:postgres /pgdata/pg_tblspc/uftm_bf1_t
chmod 700 /pgdata/pg_tblspc/uftm_bf1_i
chmod 700 /pgdata/pg_tblspc/uftm_bf1_t

# todo это лучше параметрировать через {{ db_name }}
export PGDATABASE=cfga_bf1

sudo -i -u postgres bash << EOF
export PGDATABASE=cfga_bf1

psql -c "create user uftm_bf1 with encrypted password 'StrongUserAdminPassword720!';"
psql -c "create user uftm_bf1_appl with encrypted password 'StrongUserAdminPassword720!';"
psql -c "GRANT \"as_TUZ\" TO uftm_bf1;"
psql -c "GRANT \"as_TUZ\" TO uftm_bf1_appl;"
psql -c "GRANT USAGE ON SCHEMA uftm_bf1 TO \"as_TUZ\";"
psql -c "GRANT USAGE ON SCHEMA uftm_bf1 TO as_admin_read;"
psql -c "GRANT ALL ON SCHEMA uftm_bf1 TO uftm_bf1;"
psql -c "GRANT ALL ON SCHEMA uftm_bf1 TO db_admin;"

# ------ todo это лучше параметрировать через {{ db_name }}  или задать заранее PGDATABASE
psql -c "create schema uftm_bf1 AUTHORIZATION uftm_bf1;"

psql -c "grant connect on database postgres to uftm_bf1;"
psql -c "grant all on schema uftm_bf1 to uftm_bf1;"
psql -c "alter user uftm_bf1 VALID UNTIL 'infinity';"
psql -c "grant usage on schema uftm_bf1 to uftm_bf1;"
psql -c "create tablespace uftm_bf1_t owner uftm_bf1 location '/pgdata/pg_tblspc/uftm_bf1_t';"
psql -c "create tablespace uftm_bf1_i owner uftm_bf1 location '/pgdata/pg_tblspc/uftm_bf1_i';"
psql -c "ALTER TABLESPACE uftm_bf1_t OWNER TO uftm_bf1;"
psql -c "ALTER TABLESPACE uftm_bf1_i OWNER TO uftm_bf1;"
psql -c "GRANT CREATE ON TABLESPACE uftm_bf1_t TO uftm_bf1;"
psql -c "GRANT CREATE ON TABLESPACE uftm_bf1_i TO uftm_bf1;"
psql -c "GRANT ALL ON TABLESPACE uftm_bf1_t TO uftm_bf1;"
psql -c "GRANT ALL ON TABLESPACE uftm_bf1_i TO uftm_bf1;"
psql -c "alter default privileges in schema uftm_bf1 grant ALL on tables to uftm_bf1;"
psql -c "grant select on all sequences in schema uftm_bf1 to uftm_bf1;"
psql -c "grant all privileges on all tables in schema uftm_bf1 to uftm_bf1;"
psql -c "grant select on all tables in schema uftm_bf1 to uftm_bf1;"
psql -c "ALTER ROLE uftm_bf1 SET search_path = uftm_bf1;"
psql -c "ALTER ROLE uftm_bf1_appl SET search_path = uftm_bf1;"

psql -c "CREATE SCHEMA ekpit AUTHORIZATION db_admin;"

EOF

