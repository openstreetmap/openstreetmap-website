FROM postgres:11

# Add db init script to install OSM-specific Postgres functions/extensions.
ADD docker/postgres/openstreetmap-postgres-init.sh /docker-entrypoint-initdb.d/

# Custom database functions are in a SQL file.
ADD db/functions/functions.sql /usr/local/share/osm-db-functions.sql
