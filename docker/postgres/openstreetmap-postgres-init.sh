#!/bin/bash
set -ex

# Create 'openstreetmap' user
# Password and superuser privilege are needed to successfully run test suite
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" <<-EOSQL
    CREATE USER openstreetmap SUPERUSER PASSWORD 'openstreetmap';
    GRANT ALL PRIVILEGES ON DATABASE openstreetmap TO openstreetmap;
EOSQL
