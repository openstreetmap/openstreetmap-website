#!/usr/bin/env bash
workdir=/app
set -x

echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h "$POSTGRES_HOST" -p 5432; do
  sleep 2
done


restore_db() {
  export PGPASSWORD="$POSTGRES_PASSWORD"
  curl -s -o backup.sql "$BACKUP_FILE_URL" 
  psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f backup.sql 
}

######### set up database
cat <<EOF > "$workdir/config/database.yml"
development:
  adapter: postgresql
  host: ${POSTGRES_HOST}
  database: ${POSTGRES_DB}
  username: ${POSTGRES_USER}
  password: ${POSTGRES_PASSWORD}
  encoding: utf8
EOF


######### set up database
cat <<EOF > "$workdir/config/storage.yml"
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
EOF


#### Setting up server_url and server_protocol
sed -i -e 's/^server_protocol: ".*"/server_protocol: "'$SERVER_PROTOCOL'"/g' $workdir/config/settings.yml
sed -i -e 's/^server_url: ".*"/server_url: "'$SERVER_URL'"/g' $workdir/config/settings.yml

### Setting up website status
sed -i -e 's/^status: ".*"/status: "'$WEBSITE_STATUS'"/g' $workdir/config/settings.yml

### Setting up oauth id and key for iD editor
sed -i -e 's/^#oauth_application: ".*"/oauth_application: "'$OAUTH_CLIENT_ID'"/g' $workdir/config/settings.yml
sed -i -e 's/^#oauth_key: ".*"/oauth_key: "'$OAUTH_KEY'"/g' $workdir/config/settings.yml

#### Setting up id key for the website
sed -i -e 's/^#id_application: ".*"/id_application: "'$OPENSTREETMAP_id_key'"/g' $workdir/config/settings.yml

#### Setup env vars for memcached server
sed -i -e 's/memcache_servers: \[\]/memcache_servers: "'$OPENSTREETMAP_memcache_servers'"/g' $workdir/config/settings.yml

#### Setting up nominatim url
sed -i -e 's/^nominatim_url: ".*"/nominatim_url: "'$NOMINATIM_URL'"/g' $workdir/config/settings.yml

#### Setting up required credentials 
echo $RAILS_CREDENTIALS_YML_ENC > config/credentials.yml.enc
echo $RAILS_MASTER_KEY > config/master.key 
chmod 600 config/credentials.yml.enc config/master.key


restore_db
bundle exec rails db:migrate --trace
# bundle exec rake jobs:work &
bundle exec rails server -b 0.0.0.0 -p 3000
