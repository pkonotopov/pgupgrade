#!/bin/bash

DATABASES=`psql -Atc "select datname from pg_database where datname not in ('template1','template0')"`

for q in $DATABASES; do
    echo $q;
    psql -d $q -f /var/lib/postgresql/sql/pg-post-upgrade.sql;
    psql -d $q -c "create extension if not exists pg_stat_statements";
    psql -d $q -c "create extension if not exists amcheck";
    psql -d $q -c "REINDEX (VERBOSE) DATABASE $q";
    psql -d $q -c "REINDEX (VERBOSE) SYSTEM $q";
done
