FROM postgis/postgis:14-3.5

# Add db init script to install OSM-specific Postgres user.
ADD docker/postgres/openstreetmap-postgres-init.sh /docker-entrypoint-initdb.d/
