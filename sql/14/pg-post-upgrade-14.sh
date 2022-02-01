#!/bin/bash

DATABASES=`psql -Atc "select datname from pg_database where datname not in ('template1','template0')"`

for q in $DATABASES; do
    echo $q;
    psql -d $q -f /var/lib/postgresql/sql/pg-post-upgrade.sql;
    psql -d $q -c "REINDEX (VERBOSE) DATABASE $q";
    psql -d $q -c "REINDEX (VERBOSE) SYSTEM $q";
done

# postgis related, up to PG14 version

psql -d repair -c "SELECT postgis_extensions_upgrade()"
psql -d "control-room" -c "SELECT postgis_extensions_upgrade()"

# user types redefinition
psql -d cs -f /var/lib/postgresql/sql/pg-14-aggregates-create.sql
