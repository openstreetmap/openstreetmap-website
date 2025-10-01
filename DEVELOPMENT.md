## Setup OHM Web in Development Mode
Here are simple steps to set up the OHM web application for development using Docker containers. This development setup relies on the environment variables defined in the `ohm-docker.dev.env` file. You do not need to rename this file.

To start in development mode, simply run the following command. This will launch the database, a Memcached instance, and the Rails container.

```sh
docker compose -f docker-compose.dev.yml build

## this command will bring you inside a continaer 
docker compose -f docker-compose.dev.yml run  --service-ports web bash
```

Once you are inside the container, run the following command:

```sh
./start.sh
```



If you want to restart from scratch, make sure you remove the volumes and then run the command to start the containers again

```sh
docker compose -f docker-compose.dev.yml down --remove-orphans
docker volume rm ohm-website_db-data
docker volume rm ohm-website_web-storage
docker volume rm ohm-website_web-tmp
```


## User Login
This environment comes with pre-registered users that you can use to log in and make edits in iD:

Admin: admin / 12345678
Regular user: test / 12345678


## ⚠️ Do Not Commit
This workflow modifies config/settings.yml by replacing values to make the development environment work properly.
If you're working on site improvements, please remember not to commit this file, as it has been customized specifically for local development purposes.
