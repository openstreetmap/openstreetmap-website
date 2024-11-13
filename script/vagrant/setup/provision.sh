#!/usr/bin/env bash

# abort on error
set -e

# make sure we have up-to-date packages
apt-get update

# upgrade all packages
apt-get upgrade -y

# install packages as explained in INSTALL.md
apt-get install -y ruby ruby-dev ruby-bundler \
                     libxml2-dev libxslt1-dev nodejs npm \
                     build-essential git-core firefox-esr \
                     postgresql postgresql-contrib libpq-dev libvips-dev libyaml-dev \
                     libsasl2-dev libffi-dev libgd-dev libarchive-dev libbz2-dev
npm install --global yarn

## install the bundle necessary for openstreetmap-website
pushd /srv/openstreetmap-website
# do bundle install as a convenience
bundle install --retry=10 --jobs=2
# do yarn install as a convenience
bundle exec bin/yarn install
# create user and database for openstreetmap-website
db_user_exists=`sudo -u postgres psql postgres -tAc "select 1 from pg_roles where rolname='vagrant'"`
if [ "$db_user_exists" != "1" ]; then
    sudo -u postgres createuser -s vagrant
fi

# set up sample configs
if [ ! -f config/database.yml ]; then
    sudo -u vagrant cp config/example.database.yml config/database.yml
fi
if [ ! -f config/storage.yml ]; then
    cp config/example.storage.yml config/storage.yml
fi
touch config/settings.local.yml
# create the databases
sudo -u vagrant bundle exec rails db:create
# migrate the database to the latest version
sudo -u vagrant bundle exec rails db:migrate
popd
