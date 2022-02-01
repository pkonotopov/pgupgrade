#!/bin/bash

if [[ -f /etc/walg/server-s3.conf ]]; 
  then
    set -o allexport
    source /etc/walg/server-s3.conf; 
    set +o allexport
  else
    echo "S3 configuration file not found!"
exit 1
fi

set -e

if [[ -z "$WALE_S3_PREFIX" ]]; then
  echo 'WALE_S3_PREFIX variables are undefined'
  exit 1
fi

if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo 'AWS_ACCESS_KEY_ID variables are undefined'
  exit 1
fi

if [[ -z "$AWS_ENDPOINT" ]]; then
  echo 'AWS_ENDPOINT variables are undefined'
  exit 1
fi

if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo 'AWS_SECRET_ACCESS_KEY variables are undefined'
  exit 1
fi

if [[ -z "$PGDATA" ]]; then
  echo 'PGDATA variables are undefined'
  exit 1
fi

/bin/wal-g backup-fetch "$@"
touch $PGDATA/recovery.signal
