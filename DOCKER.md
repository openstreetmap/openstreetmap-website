# Using Docker to run OpenStreetMap

Using [Docker](https://www.docker.com/) will allow you to install the OpenStreetMap application and all its' dependencies in a container, almost with a single command.

These instructions gloss over the precise details of the dependencies and their configuration but these can be found in full detail at [INSTALL.md](INSTALL.md).

The first step is to fork/clone the repo to your local machine. The repository is reasonably large (~150MB) and it's unlikely that you need the full history. If you are happy to wait for it all to download, run:
```
git clone https://github.com/openstreetmap/openstreetmap-website.git
```

To clone only the most recent version (~23MB), instead use a 'shallow clone':

```
git clone --depth=1 https://github.com/openstreetmap/openstreetmap-website.git
```

Now change working directory to the `openstreetmap-website`:

```
cd openstreetmap-website
```

### Storage setup

```
cp config/example.storage.yml config/storage.yml
```

### Database

```
cp config/example.database.yml config/database.yml
```

Set `username` to postgres and `host` to db leave the `password` blank


### App configuration

```
cp config/settings.yml config/settings.local.yml
```

### Installation

In the root directory run:

```
docker-compose -f docker/docker-compose.yml up
```
Now if this is your first time running or you have removed cache this will take some time to complete. So grab tea/coffee and seat tight. Upon successfull build it should show

### Migrations
While `docker-compose up` is running, open another terminal windows and run:

```
docker-compose -f docker/docker-compose.yml exec web bundle exec rake db:migrate
```

### Node.js modules
We use Yarn to manage the Node.js modules required for the project.:

```
docker-compose -f docker/docker-compose.yml exec web bundle exec rake yarn:install
```

Once these are complete you should be able to visit the app at http://localhost:3000

If localhost does not work, you can use the IP address of the docker-machine.

### Tests

```
docker-compose -f docker/docker-compose.yml exec web bundle exec rake test:db
```

### Bash

If you want to get onto the web container and run specific commands you can fire up bash via:

```
docker-compose -f docker/docker-compose.yml exec web /bin/bash
```

Similarly, if you want to get onto the db container use:

```
docker-compose -f docker/docker-compose.yml exec db /bin/bash
```

### Populating the database
This  installation comes with no geographic data loaded. You can either create new data using one of the editors (Potlatch 2, iD, JOSM etc) or by loading an OSM extract.

After installing but before creating any users or data, import an extract with [Osmosis](https://wiki.openstreetmap.org/wiki/Osmosis) and the `--write-apidb` task. The `web` container comes with `osmosis` pre-installed. So to populate data with a `.osm.pbf` use the following command:

```
docker-compose -f docker/docker-compose.yml exec web osmosis --read-pbf /path/to/file.osm.pbf --write-apidb host="db" database="openstreetmap" user="postgres"  validateSchemaVersion="no"
```
