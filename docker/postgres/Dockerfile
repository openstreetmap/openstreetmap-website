FROM postgres:11

RUN apt-get update && \
    apt-get install -y \
      build-essential \
      curl \
      postgresql-server-dev-all && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Add custom database functions
ADD db/functions/ /app/db/functions/

# Get quad_tile.h header file from quad_tile repository and
# use it to make libpgosm.so for OSM-specific Postgres functions.
RUN cd db/functions && \
    curl -# -O https://raw.githubusercontent.com/openstreetmap/quad_tile/9fcba83fcbca8a206fa518da5a52f840dc2ecb09/ext/quad_tile/quad_tile.h && \
    make -e QTDIR=/app/db/functions libpgosm.so

# Add db init script to install OSM-specific Postgres functions
ADD docker/postgres/openstreetmap-postgres-init.sh /docker-entrypoint-initdb.d/
