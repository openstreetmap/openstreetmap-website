# Would use a docker postgis image, but it doesn't work with Apple Silicon
# (https://github.com/postgis/docker-postgis/issues/216).
# Therefore we use a postgres image and apt-install Postgis ourselves.
FROM postgres:17

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
    postgresql-17-postgis-3

# Add db init script to install OSM-specific Postgres user.
ADD docker/postgres/openstreetmap-postgres-init.sh /docker-entrypoint-initdb.d/
