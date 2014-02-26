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
sudo -u postgres createuser -s vagrant
sudo -u vagrant -H createdb -E UTF-8 -O vagrant openstreetmap
sudo -u vagrant -H createdb -E UTF-8 -O vagrant osm_test
# add btree_gist extension
sudo -u vagrant -H psql -c "create extension btree_gist" openstreetmap
# TODO: build and set up postgres extensions
# set up sample configs
sudo -u vagrant cp config/example.database.yml config/database.yml
sudo -u vagrant cp config/example.application.yml config/application.yml
popd
