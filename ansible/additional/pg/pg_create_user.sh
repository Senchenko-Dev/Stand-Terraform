#!/usr/bin/env bash
sudo -i -u postgres bash << EOF
psql -c "CREATE USER dbadmin WITH ENCRYPTED PASSWORD 'StrongUserAdminPassword720!' NOINHERIT;"
psql -c "GRANT db_admin TO dbadmin;"
EOF

#  -- Создание Администратора СУБД
#  CREATE USER user_db WITH ENCRYPTED PASSWORD 'xxxxxxxxxxxx' NOINHERIT;
#  GRANT db_admin TO user_db;
#
#  -- Создание Администратора АС
#  CREATE USER user_as WITH ENCRYPTED PASSWORD 'xxxxxxxxxxxx' NOINHERIT;
#  GRANT as_admin TO user_as;


sudo -i -u postgres bash << EOF
psql -c "CREATE USER cfga_bf1 WITH ENCRYPTED PASSWORD 'StrongUserAdminPassword720!' INHERIT;"
psql -c "GRANT \"as_TUZ\" TO cfga_bf1;"
psql -c "CREATE USER cfge_bf1 WITH ENCRYPTED PASSWORD 'StrongUserAdminPassword720!' INHERIT;"
psql -c "GRANT \"as_TUZ\" TO cfge_bf1;"
EOF

#sudo -i -u postgres bash << EOF
#psql -c "CREATE USER currency_rates WITH ENCRYPTED PASSWORD 'StrongUserAdminPassword720!' INHERIT;"
#psql -c "GRANT \"as_TUZ\" TO currency_rates;"
#psql -c "create schema dyncontent"
#psql -c "ALTER ROLE currency_rates SET search_path = currency_rates;"
#psql -c "GRANT USAGE ON SCHEMA currency_rates to currency_rates;"
#EOF
#
#
#sudo -i -u postgres bash << EOF
#psql -c "CREATE USER dyncontent WITH ENCRYPTED PASSWORD 'StrongUserAdminPassword720!' INHERIT;"
#psql -c "GRANT \"as_TUZ\" TO dyncontent;"
#psql -c "create schema dyncontent"
#psql -c "ALTER ROLE dyncontent SET search_path = dyncontent;"
#psql -c "GRANT USAGE ON SCHEMA dyncontent to dyncontent;"
#EOF
#
#
