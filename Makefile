docker-build:
	docker-compose build

docker-up:
	docker-compose up -d

docker-db-migrate:
	docker-compose run --rm web rake db:migrate

docker-test:
	docker-compose run --rm web rake test:db

docker-populate-db:
	wget https://download.geofabrik.de/north-america/us/district-of-columbia-latest.osm.pbf
	docker-compose run --rm web osmosis \
		-verbose	\
		--read-pbf district-of-columbia-latest.osm.pbf \
		--write-apidb \
			host="db" \
			database="openstreetmap" \
			user="openstreetmap" \
			validateSchemaVersion="no"
