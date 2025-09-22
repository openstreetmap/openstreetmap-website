#!/usr/bin/env bash
workdir=/app
set -x
restore_db() {
  export PGPASSWORD="$POSTGRES_PASSWORD"
  curl -s -o backup.sql "$BACKUP_FILE_URL" || {
    echo "Error: Failed to download backup file."
    exit 1
  }

  psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f backup.sql && \
    echo "Database restored successfully." || \
    { echo "Database restore failed."; exit 1; }
}

restore_db

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

#### Setting up server_url and server_protocol
sed -i -e 's/^server_protocol: ".*"/server_protocol: "'$SERVER_PROTOCOL'"/g' $workdir/config/settings.yml
sed -i -e 's/^server_url: ".*"/server_url: "'$SERVER_URL'"/g' $workdir/config/settings.yml

### Setting up website status
sed -i -e 's/^status: ".*"/status: "'$WEBSITE_STATUS'"/g' $workdir/config/settings.yml

### Setting up oauth id and key for iD editor
sed -i -e 's/^oauth_application: ".*"/oauth_application: "'$OAUTH_CLIENT_ID'"/g' $workdir/config/settings.yml
sed -i -e 's/^oauth_key: ".*"/oauth_key: "'$OAUTH_KEY'"/g' $workdir/config/settings.yml

#### Setting up id key for the website
sed -i -e 's/^id_application: ".*"/id_application: "'$OPENSTREETMAP_id_key'"/g' $workdir/config/settings.yml

#### Setup env vars for memcached server
sed -i -e 's/memcache_servers: \[\]/memcache_servers: "'$OPENSTREETMAP_memcache_servers'"/g' $workdir/config/settings.yml

#### Setting up nominatim url
sed -i -e 's/^nominatim_url: ".*"/nominatim_url: "'$NOMINATIM_URL'"/g' $workdir/config/settings.yml


bundle exec rails db:migrate --trace
bundle exec rake jobs:work &
bundle exec rails server -b 0.0.0.0 -p 3000
