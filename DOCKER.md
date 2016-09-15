# Using Docker to run OpenStreetMap

Using [Docker](https://www.docker.com/) will allow you to install the OpenStreetMap application and all its' dependencies in a container, almost with a single command.

These instructions gloss over the precise details of the dependencies and their configuration but these can be found in full detail at [INSTALL.md](INSTALL.md).

The first step is to fork/clone the repo to your local machine. Then run these commands:

### App configuration

```
cp config/example.application.yml config/application.yml
```

### Database

```
cp config/example.database.yml config/database.yml
```

Set `username` to postgres and `host` to db leave the password blank

### Installation

In the root directory run:

```
docker-compose up
```

### Migrations

```
docker-compose exec web bundle exec rake db:migrate
```

Once these are complete you should be able to visit the app at http://localhost:3000

If localhost does not work, you can use the IP address of the docker-machine.

### Tests

```
docker-compose exec web bundle exec rake test:db
```

### Bash

If you want to get onto the web container and run specific commands you can fire up bash via:

```
docker-compose exec web /bin/bash
```

Similarly, if you want to get onto the db container use:

```
docker-compose exec db /bin/bash
```

### General Information

The [docker-compose.yml](docker-compose.yml) specifies the configuration for the two web and db containers. For example port that the Postgres database is exposed on that you can point your local db admin tool at.

Note that the [Dockerfile.postgres](Dockerfile.postgres) for the db container includes various build tools to run [db/docker_postgres.sh](db/docker_postgres.sh). This script installs extensions and functions required by the database and it is run automatically because it is specifically added to the location `docker-entrypoint-initdb.d` on the container.

There is a [.dockerignore](.dockerignore) that ignores all files except those required to be added to the containers.
