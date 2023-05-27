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