#!/usr/bin/env sh
set -e

SERVICE_NAME=$1;

case "$SERVICE_NAME" in
  --upgrade)
    bash ${PGHOME}/postgresql-upgrade.sh
    ;;
  *)
    exec /var/lib/postgresql/.local/bin/patroni /etc/patroni/patroni.yml
    ;;
esac
