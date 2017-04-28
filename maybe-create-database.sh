#! /bin/bash

sleep 5 # wait for database to be available.

mysqlshow $ZM_DB_NAME -h $ZM_DB_HOST -u $ZM_DB_USER > /dev/null 2>&1 || \
  # Database does not exist, run the creation script.
  mysql -h $ZM_DB_HOST -u $ZM_DB_USER < /usr/share/zoneminder/db/zm_create.sql
