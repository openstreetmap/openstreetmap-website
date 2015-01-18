#!/usr/bin/env bash

# set locale to UTF-8 compatible. apologies to non-english speakers...
update-locale LANG=en_GB.utf8 LC_ALL=en_GB.utf8
locale-gen
export LANG=en_GB.utf8
export LC_ALL=en_GB.utf8

# make sure we have up-to-date packages
apt-get update

## vagrant grub-pc fix from: https://gist.github.com/jrnickell/6289943
# parameters
echo "grub-pc grub-pc/kopt_extracted boolean true" | debconf-set-selections
echo "grub-pc grub2/linux_cmdline string" | debconf-set-selections
echo "grub-pc grub-pc/install_devices multiselect /dev/sda" | debconf-set-selections
echo "grub-pc grub-pc/install_devices_failed_upgrade boolean true" | debconf-set-selections
echo "grub-pc grub-pc/install_devices_disks_changed multiselect /dev/sda" | debconf-set-selections
# vagrant grub fix
dpkg-reconfigure -f noninteractive grub-pc

# upgrade all packages
apt-get upgrade -y

# install packages as explained in INSTALL.md
apt-get install -y ruby1.9.1 libruby1.9.1 ruby1.9.1-dev ri1.9.1 \
    libmagickwand-dev libxml2-dev libxslt1-dev nodejs \
    apache2 apache2-threaded-dev build-essential git-core \
    postgresql postgresql-contrib libpq-dev postgresql-server-dev-all \
    libsasl2-dev
gem1.9.1 install bundle

## install the bundle necessary for openstreetmap-website
pushd /srv/openstreetmap-website
# do bundle install as a convenience
sudo -u vagrant -H bundle install
# create user and database for openstreetmap-website
db_user_exists=`sudo -u postgres psql postgres -tAc "select 1 from pg_roles where rolname='vagrant'"`
if [ "$db_user_exists" != "1" ]; then
		sudo -u postgres createuser -s vagrant
		sudo -u vagrant -H createdb -E UTF-8 -O vagrant openstreetmap
		sudo -u vagrant -H createdb -E UTF-8 -O vagrant osm_test
		# add btree_gist extension
		sudo -u vagrant -H psql -c "create extension btree_gist" openstreetmap
		sudo -u vagrant -H psql -c "create extension btree_gist" osm_test
fi
# build and set up postgres extensions
pushd db/functions
sudo -u vagrant make
sudo -u vagrant psql openstreetmap -c "drop function if exists maptile_for_point(int8, int8, int4)"
sudo -u vagrant psql openstreetmap -c "CREATE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4 AS '/srv/openstreetmap-website/db/functions/libpgosm.so', 'maptile_for_point' LANGUAGE C STRICT"
popd
# set up sample configs
if [ ! -f config/database.yml ]; then
		sudo -u vagrant cp config/example.database.yml config/database.yml
fi
if [ ! -f config/application.yml ]; then
		sudo -u vagrant cp config/example.application.yml config/application.yml
fi
# migrate the database to the latest version
sudo -u vagrant rake db:migrate
popd
