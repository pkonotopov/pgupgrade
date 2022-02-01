#!/bin/bash
# Script for upgrading PostgreSQL 12 to PostgreSQL 13
#

set -e

PGDATA_COMMON=/var/lib/postgresql/data
PGBIN_COMMON=/usr/lib/postgresql
PGHOME=/var/lib/postgresql
PG_USER=${PG_USER_EXT}
CLUSTER_NAME=${CLUSTER_NAME_EXT}

# Script logging
mkdir -p ${PGDATA_COMMON}/logs
cd ${PGDATA_COMMON}/logs

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>${PGDATA_COMMON}/logs/pg_upgrade.log 2>&1

printf "\nStarting upgrade `date`\n"

# Script configuration

# Versions, chech env variables

if [[ -z "${PG_VERSION_OLD}" ]]; then
  echo "PG_VERSION_OLD is undefined"
  exit 1
else
  PG_MAJOR_OLD_S="${PG_VERSION_OLD}"
fi

if [[ -z "${PG_VERSION_NEW}" ]]; then
  echo "PG_VERSION_NEW is undefined"
  exit 1
else
  PG_MAJOR_NEW_S=${PG_VERSION_NEW}
fi

# PGDATA
PGDATAOLD=${PGDATA_COMMON}/${PG_MAJOR_OLD_S}
PGDATANEW=${PGDATA_COMMON}/${PG_MAJOR_NEW_S}

PGBACKUPOLD=${PGBACKUP_COMMON}/${PG_MAJOR_OLD_S}
PGBACKUPNEW=${PGBACKUP_COMMON}/${PG_MAJOR_NEW_S}

# PGBIN
PGBINOLD=${PGBIN_COMMON}/${PG_MAJOR_OLD_S}/bin
PGBINNEW=${PGBIN_COMMON}/${PG_MAJOR_NEW_S}/bin

# Patroni config file
PATRONI_CONFIG_PATH=/etc/patroni/patroni.yml

JOBS=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1)

PG_UPGRADE_COMMAND=(${PGBINNEW}/pg_upgrade \
  --link \
  --jobs=${JOBS} \
  --username=${PG_USER} \
  --old-datadir=${PGDATAOLD} \
  --new-datadir=${PGDATANEW} \
  --old-bindir=${PGBINOLD} \
  --new-bindir=${PGBINNEW} \
  --old-options '-c config_file=${PGDATAOLD}/postgresql.conf' \
  --new-options '-c config_file=${PGDATANEW}/postgresql.conf')

# Check if we have enough space for pg_upgrade or not

check_pgdata_space () {

PGDATA_ACTUAL_SIZE=`du -ks ${PGDATAOLD} | awk '{print $1}'`
PGDATA_FREE_SPACE=`df ${PGDATA_COMMON} | awk '/[0-9]%/{print $(NF-2)}'`

if [[ $(( ${PGDATA_ACTUAL_SIZE} * 3 )) -gt ${PGDATA_FREE_SPACE} ]]; then
  printf "Don't have enough space for pg_upgrade. Exit.\n"
  exit 1
else
  printf "There is enough space for pg_upgrade. Continue.\n"
fi

}
check_pgdata_space

# Create OLD PGDATA backup

make_backup () {
  mkdir -p ${PGDATA_COMMON}/backup/upgrade
  cp -r ${PGDATAOLD} ${PGDATA_COMMON}/backup/upgrade
}
make_backup

# Init postgresql 13 cluster
# We presume that PGDATAOLD is already exist. Uncomment below lines for local tests
#chmod 700 -R $PGDATAOLD
#chown -R postgres $PGDATAOLD

init_new_pgdata () {

mkdir -p ${PGDATANEW}
chmod 700 ${PGDATANEW}
chown -R postgres:postgres ${PGDATANEW}

rm -rf ${PGDATANEW}/*
${PGBINNEW}/initdb --username=${PG_USER} --encoding=UTF8 --locale=en_US.utf-8 --data-checksums --allow-group-access ${PGDATANEW}

}
init_new_pgdata

# Update pg_hba and postgresql config files before upgrade

if `grep local ${PGDATAOLD}/pg_hba.conf`; then
  printf "Connection line for local already exist in pg_hba.conf"
else
  sed -i '/^# It will be*/a local all all trust' ${PGDATAOLD}/pg_hba.conf
fi
echo "shared_preload_libraries='pg_stat_statements'" >> ${PGDATANEW}/postgresql.conf

# Run upgrade only if pg_upgrade with check is success

if "${PG_UPGRADE_COMMAND[@]}" --check; then
  printf '\nYou can proceed with pg_upgrade\n'
  "${PG_UPGRADE_COMMAND[@]}"
  upgradeRetVal=$?
else
  printf '\npg_upgrade process with check exit with error\n'
  exit
fi

# Post-upgrade tasks
# - Change binaries to 13 in Patroni configuration file
# - Change wal_keep_segments to wal_keep_size

if [[ upgradeRetVal -eq 0 ]]; then
  cp ${PGDATAOLD}/patroni.dynamic.json ${PGDATANEW}/patroni.dynamic.json
else
  printf 'Upgrade executed with errors. Exit'
  exit
fi

# Switch data directories

# if [[ upgradeRetVal -eq 0 ]]; then
#   printf 'Switching PGDATA directories\n'
#   mv "${PGDATAOLD}" "${PGDATAOLD}"
#   mv "${PGDATANEW}" "${PGDATAOLD}"
# else
#   printf 'Upgrade executed with errors. Exit'
# fi

/var/lib/postgresql/.local/bin/patronictl -k -c /etc/patroni/patroni.yml remove ${CLUSTER_NAME} <<EOF
${CLUSTER_NAME}
Yes I am aware
EOF

printf "\nYou can start PostgreSQL 13 container on current node\n"
printf "Finishing upgrade `date`\n"
