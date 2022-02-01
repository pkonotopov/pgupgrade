ARG DEBIAN_VER
ARG PG_MAJOR
ARG PG_MINOR

FROM postgres:${PG_MAJOR}.${PG_MINOR}-${DEBIAN_VER}

# Postgres
ARG DEBIAN_VER
ARG PG_MAJOR
ARG PG_MINOR

# Postgis
ARG POSTGIS_MAJOR
ARG POSTGIS_VERSION

# pg_profile
ARG PG_PROFILE_VERSION

# Backup tools
ARG WALG=false
ARG PROBACKUP=false
ARG WALG_VERSION

# Postgis upgrade
ARG POSTGIS_UPGRADE=false
ARG POSTGIS_MAJOR_NEW
ARG POSTGIS_VERSION_NEW

ENV PG_MAJOR=${PG_MAJOR} \
    POSTGIS_MAJOR=${POSTGIS_MAJOR} \
    PG_BIN_DIR=/usr/lib/postgresql/${PG_MAJOR}/bin \
    POSTGIS_VERSION=${POSTGIS_VERSION} \
    POSTGIS_MAJOR_NEW=${POSTGIS_MAJOR_NEW} \
    POSTGIS_VERSION_NEW=${POSTGIS_VERSION_NEW} \
    POSTGIS_UPGRADE=${POSTGIS_UPGRADE} \
    DEBIAN_VER=${DEBIAN_VER} \
    PG_PROFILE_VERSION=${PG_PROFILE_VERSION} \
    WALG_VERSION=${WALG_VERSION} \
    WALG=${WALG} \
    PROBACKUP=${PROBACKUP}

RUN set -ex \
    && ulimit -s unlimited \
    && usermod -u 2001 postgres \
    && groupmod -g 2001 postgres \
    && apt-get update \
    && apt-get install -y wget \
    && printf "deb https://apt-archive.postgresql.org/pub/repos/apt ${DEBIAN_VER}-pgdg-archive main" >> /etc/apt/sources.list.d/pgdg.list \
    && wget -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && printf "deb [arch=amd64] https://repo.postgrespro.ru/pg_probackup/deb/ ${DEBIAN_VER} main-${DEBIAN_VER}" >> /etc/apt/sources.list.d/pg_probackup.list \
    && wget -O - https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG_PROBACKUP | apt-key add - \
    && apt-get update \
    && apt-get install -y \
        wget curl \
        python3-psycopg2 \
        python3-pip \
        postgresql-${PG_MAJOR}-wal2json \
        postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR}=${POSTGIS_VERSION} \
        postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR}-scripts \
        postgresql-${PG_MAJOR}-repack

RUN if [ "$POSTGIS_UPGRADE" = "true" ]; then \
    set -ex \
    && apt-get install -y \
        postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR_NEW}=${POSTGIS_VERSION_NEW} \
        postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR_NEW}-scripts; \
    fi

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && cd /usr/src \
    && wget -q https://github.com/zubkov-andrei/pg_profile/releases/download/${PG_PROFILE_VERSION}/pg_profile--${PG_PROFILE_VERSION}.tar.gz \
    && tar xzf pg_profile--${PG_PROFILE_VERSION}.tar.gz --directory $(/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config --sharedir)/extension \
    && rm -rf /usr/src/pg_profile--${PG_PROFILE_VERSION}.tar.gz \
    && mkdir -p /etc/walg

COPY $PWD/scripts/*.sh /etc/walg

RUN if [ "$WALG" = "true" ]; then \
        set -ex \
        && wget -q https://github.com/wal-g/wal-g/releases/download/${WALG_VERSION}/wal-g-pg-ubuntu-20.04-amd64 \
        && mv ./wal-g-pg-ubuntu-20.04-amd64 /bin/wal-g \
        && chmod +x /bin/wal-g \
        && chown postgres:postgres /etc/walg -R \
        && chmod +x /etc/walg/*.sh; \
    else \
        rm -rf /etc/walg; \
    fi

RUN if [ "$PROBACKUP" = "true" ]; then \
        set -ex \
        && apt-get update \
        && apt-get install -y pg-probackup-${PG_MAJOR}; \
    fi

USER postgres

RUN pip3 install --no-cache-dir --user patroni[raft,consul] python-consul2

ENTRYPOINT []

