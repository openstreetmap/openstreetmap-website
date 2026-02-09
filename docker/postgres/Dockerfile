FROM postgres:14

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
    postgresql-14-postgis-3

# Add db init script to install OSM-specific Postgres user.
ADD docker/postgres/openstreetmap-postgres-init.sh /docker-entrypoint-initdb.d/
