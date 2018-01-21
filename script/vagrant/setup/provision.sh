#!/usr/bin/env bash

# abort on error
set -e

# set locale to UTF-8 compatible. apologies to non-english speakers...
locale-gen en_GB.utf8
update-locale LANG=en_GB.utf8 LC_ALL=en_GB.utf8
export LANG=en_GB.utf8
export LC_ALL=en_GB.utf8

# make sure we have up-to-date packages
apt-get update

# upgrade all packages
apt-get upgrade -y

# install packages as explained in INSTALL.md
apt-get install -y ruby2.3 libruby2.3 ruby2.3-dev \
                     libmagickwand-dev libxml2-dev libxslt1-dev nodejs \
                     apache2 apache2-dev build-essential git-core \
                     postgresql postgresql-contrib libpq-dev postgresql-server-dev-all \
                     libsasl2-dev imagemagick
gem2.3 install bundler

## install the bundle necessary for openstreetmap-website
pushd /srv/openstreetmap-website
# do bundle install as a convenience
sudo -u ubuntu -H bundle install --retry=10 --jobs=2
# create user and database for openstreetmap-website
db_user_exists=`sudo -u postgres psql postgres -tAc "select 1 from pg_roles where rolname='ubuntu'"`
if [ "$db_user_exists" != "1" ]; then
		sudo -u postgres createuser -s ubuntu
		sudo -u ubuntu createdb -E UTF-8 -O ubuntu openstreetmap
		sudo -u ubuntu createdb -E UTF-8 -O ubuntu osm_test
		# add btree_gist extension
		sudo -u ubuntu psql -c "create extension btree_gist" openstreetmap
		sudo -u ubuntu psql -c "create extension btree_gist" osm_test
fi
# build and set up postgres extensions
pushd db/functions
sudo -u ubuntu make
sudo -u ubuntu psql openstreetmap -c "CREATE OR REPLACE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4 AS '/srv/openstreetmap-website/db/functions/libpgosm.so', 'maptile_for_point' LANGUAGE C STRICT"
sudo -u ubuntu psql openstreetmap -c "CREATE OR REPLACE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '/srv/openstreetmap-website/db/functions/libpgosm.so', 'tile_for_point' LANGUAGE C STRICT"
sudo -u ubuntu psql openstreetmap -c "CREATE OR REPLACE FUNCTION xid_to_int4(xid) RETURNS int4 AS '/srv/openstreetmap-website/db/functions/libpgosm.so', 'xid_to_int4' LANGUAGE C STRICT"
popd
# set up sample configs
if [ ! -f config/database.yml ]; then
		sudo -u ubuntu cp config/example.database.yml config/database.yml
fi
if [ ! -f config/application.yml ]; then
		sudo -u ubuntu cp config/example.application.yml config/application.yml
fi
# migrate the database to the latest version
sudo -u ubuntu rake db:migrate
popd
