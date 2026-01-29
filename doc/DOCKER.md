# Using Docker and Docker Compose for Development and Testing

These instructions are designed for setting up `openstreetmap-website` for development and testing using [Docker](https://www.docker.com/). This will allow you to install the OpenStreetMap application and all its dependencies in Docker images and then run them in containers, almost with a single command.

## Install Docker

### Windows

1. Use Docker Desktop via [docker.com Download](https://www.docker.com/products/docker-desktop/).

2. You have to enable git symlinks before cloning the repository.
   This repository uses symbolic links that are not enabled by default on Windows git. To enable them, [turn on Developer Mode](https://windowsreport.com/windows-11-developer-mode/) on Windows and run `git config --global core.symlinks true` to enable symlinks in Git. See [this StackOverflow question](https://stackoverflow.com/questions/5917249/git-symbolic-links-in-windows) for more information.

### Mac

- Use Docker Desktop via [docker.com Download](https://www.docker.com/products/docker-desktop/).
- Or [Homebrew](https://formulae.brew.sh/cask/docker).

### Linux

Use [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) with the [docker-compose-plugin](https://docs.docker.com/compose/install/linux/)

## Clone repository

The first step is to fork/clone the repo to your local machine:

```bash
git clone https://github.com/openstreetmap/openstreetmap-website.git
```

Now change working directory to the `openstreetmap-website`:

```bash
cd openstreetmap-website
```

## Initial Setup

### Storage

```bash
cp config/example.storage.yml config/storage.yml
```

### Database

```bash
cp config/docker.database.yml config/database.yml
```

## Prepare local settings file

This is a workaround. [See issues/2185 for details](https://github.com/openstreetmap/openstreetmap-website/issues/2185#issuecomment-508676026).

```bash
touch config/settings.local.yml
```

**Windows users:** `touch` is not an available command in Windows so just create a `settings.local.yml` file in the `config` directory, or if you have WSL you can run `wsl touch config/settings.local.yml`.

## Installation

To build local Docker images run from the root directory of the repository:

```bash
docker compose build
```

If this is your first time running or you have removed cache this will take some time to complete. Once the Docker images have finished building you can launch the images as containers.

To launch the app run:

```bash
docker compose up -d
```

This will launch one Docker container for each 'service' specified in `docker-compose.yml` and run them in the background. There are two options for inspecting the logs of these running containers:

- You can tail logs of a running container with a command like this: `docker compose logs -f web` or `docker compose logs -f db`.
- Instead of running the containers in the background with the `-d` flag, you can launch the containers in the foreground with `docker compose up`. The downside of this is that the logs of all the 'services' defined in `docker-compose.yml` will be intermingled. If you don't want this you can mix and match - for example, you can run the database in background with `docker compose up -d db` and then run the Rails app in the foreground via `docker compose up web`.

## Running commands

At this point, the Docker container can be used although there are a couple of steps missing to complete the install.

From now on, any commands should be run within the container. To do this, first you need to open a shell within it:

```bash
docker compose run --rm web bash
```

This will open a shell where you can enter commands. These commands will run within the context of the container, without affecting your own machine outside your working directory.

> [!IMPORTANT]
> Unless otherwise stated, make sure that you are in this shell when following any other instructions.

### Create the databases

To create all databases and set up all databases, run:

```bash
bundle exec rails db:create
```

## Validate Your Installation

Hopefully that's it? Let's check that things are working properly.

### Run the tests

Run the test suite:

```bash
bundle exec rails test:all
```

This test will take a few minutes, reporting tests run, assertions, and any errors. If you receive no errors, then your installation was successful. On occasion some tests may fail randomly and will pass if run again. We are working towards avoiding this, but it can still happen.

> [!NOTE]
> The unit tests may output parser errors related to "Attribute lat redefined." These can be ignored.

### Start the development server

Rails comes with a built-in webserver, so that you can test on your own machine without needing a server. Run:

```bash
bundle exec rails server
```

You can now view the site in your favourite web browser at [http://localhost:3000/](http://localhost:3000/)

> [!NOTE]
> The OSM map tiles you see aren't created from your local database - they are the production map tiles, served from a separate service over the Internet.

## What's next?

🎉 **Congratulations!** You have successfully installed the OpenStreetMap website.

**Next steps:**
* **Configuration:** See [CONFIGURE.md](CONFIGURE.md) for populating the database with data, creating users, setting up OAuth, and other configuration tasks.
* **Contributing:** Check out [CONTRIBUTING.md](../CONTRIBUTING.md) for coding style guidelines, testing procedures, and how to submit your contributions.

Don't forget to **run any commands in a shell within the container**, as instructed above under "Running commands".
