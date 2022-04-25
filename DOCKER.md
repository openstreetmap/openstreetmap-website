# Using Docker and Docker Compose for Development and Testing

These instructions are designed for setting up The Rails Port for development and testing using [Docker](https://www.docker.com/). This will allow you to install the OpenStreetMap application and all its dependencies in Docker images and then run them in containers, almost with a single command. You will need to install Docker and Docker Compose on your development machine:

- [Install Docker](https://docs.docker.com/install/)
- [Install Docker Compose](https://docs.docker.com/compose/install/)

The first step is to fork/clone the repo to your local machine:

    git clone https://github.com/openstreetmap/openstreetmap-website.git

Now change working directory to the `openstreetmap-website`:

    cd openstreetmap-website

## Initial Setup

### Storage

    cp config/example.storage.yml config/storage.yml

### Database

    cp config/docker.database.yml config/database.yml

## Prepare local settings file

This is a workaround. [See issues/2185 for details](https://github.com/openstreetmap/openstreetmap-website/issues/2185#issuecomment-508676026).

    touch config/settings.local.yml

## Installation

To build local Docker images run from the root directory of the repository:

    docker-compose build

If this is your first time running or you have removed cache this will take some time to complete. Once the Docker images have finished building you can launch the images as containers.

To launch the app run:

    docker-compose up -d

This will launch one Docker container for each 'service' specified in `docker-compose.yml` and run them in the background. There are two options for inspecting the logs of these running containers:

- You can tail logs of a running container with a command like this: `docker-compose logs -f web` or `docker-compose logs -f db`.
- Instead of running the containers in the background with the `-d` flag, you can launch the containers in the foreground with `docker-compose up`. The downside of this is that the logs of all the 'services' defined in `docker-compose.yml` will be intermingled. If you don't want this you can mix and match - for example, you can run the database in background with `docker-compose up -d db` and then run the Rails app in the foreground via `docker-compose up web`.

### Migrations

Run the Rails database migrations:

    docker-compose run --rm web bundle exec rake db:migrate

### Tests

Run the test suite by running:

    docker-compose run --rm web bundle exec rails test:all

### Loading an OSM extract

This installation comes with no geographic data loaded. You can either create new data using one of the editors (Potlatch 2, iD, JOSM etc) or by loading an OSM extract. Here an example for loading an OSM extract into your Docker-based OSM instance.

For example, let's download the District of Columbia from Geofabrik or [any other region](https://download.geofabrik.de):

    wget https://download.geofabrik.de/north-america/us/district-of-columbia-latest.osm.pbf

You can now use Docker to load this extract into your local Docker-based OSM instance:

    docker-compose run --rm web osmosis \
        -verbose    \
        --read-pbf district-of-columbia-latest.osm.pbf \
        --log-progress \
        --write-apidb \
            host="db" \
            database="openstreetmap" \
            user="openstreetmap" \
            validateSchemaVersion="no"

Once you have data loaded for Washington, DC you should be able to navigate to [`http://localhost:3000/#map=12/38.8938/-77.0146`](http://localhost:3000/#map=12/38.8938/-77.0146) to begin working with your local instance.

### Additional Configuration

See [`CONFIGURE.md`](CONFIGURE.md) for information on how to manage users and enable OAuth for iD, JOSM etc.

### Bash

If you want to get into a web container and run specific commands you can fire up a throwaway container to run bash in via:

    docker-compose run --rm web bash

Alternatively, if you want to use the already-running `web` container then you can `exec` into it via:

    docker-compose exec web bash

Similarly, if you want to `exec` in the db container use:

    docker-compose exec db bash
