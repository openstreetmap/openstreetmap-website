# Installation

These instructions are designed for setting up The Rails Port for development and testing.
If you want to deploy the software for your own project, then see the notes at the end.

These instructions are based on Ubuntu 12.04 LTS, which is the platform used by the OSMF servers.
The instructions also work, with only minor amendments, for all other current Ubuntu releases.

For other operating systems see

* [Fedora](INSTALL-fedora.md)
* [MacOSX](INSTALL-macosx.md)

We don't recommend attempting to develop or deploy this software on Windows. If you need to, try using
Ubuntu in a virtual machine.

## Dependencies

Many of the dependencies are managed through the standard Ruby on Rails mechanisms -
i.e. ruby gems specified in the Gemfile and installed using bundler. However, there are a large number
of packages required before you can get the various gems installed.

## Minimum requirements

* Ruby 1.8.7 or 1.9.3
* RubyGems 1.3.1+
* Postgres 8.3+
* ImageMagick
* Bundler

These can be installed on Ubuntu 10.10 or later with:

```
sudo apt-get install ruby libruby ruby-dev rdoc ri ruby-bundler rubygems \
                     libmagickwand-dev libxml2-dev libxslt1-dev \
                     apache2 apache2-threaded-dev build-essential git-core \
                     postgresql postgresql-contrib libpq-dev postgresql-server-dev-all \
                     libsasl2-dev
```
## Ruby gems

We use [Bundle](http://gembundler.com/) to manage the rubygems required for the project.

```
git clone https://github.com/openstreetmap/openstreetmap-website.git
cd openstreetmap-website
bundle install
```

## Application setup

We need to create the `config/application.yml` file from the example template. This contains various configuration options.

```
cp config/example.application.yml config/application.yml
```

You can customize your installation of The Rails Port by changing the values in `config/application.yml`

## Database setup

The Rails Port uses three databases -  one for development, one for testing, and one for production. The database-specific configuration
options are stored in `config/database.yml`, which we need to create from the example template.

```
cp config/example.database.yml config/database.yml
```

PostgreSQL is configured to, by default, accept local connections without requiring a username or password. This is fine for development.
If you wish to set up your database differently, then you should change the values found in the `config/database.yml` file, and amend the
instructions below as appropriate.

### PostgreSQL account setup

We need to create a PostgreSQL role (i.e. user account) for your current user, and it needs to be a superuser so that we can create more database.

```
sudo -u postgres -i
createuser -s <username>
exit
```

### Create the databases

To create the three databases - for development, testing and production - run:

```
bundle exec rake db:create
```

### PostgreSQL Btree-gist Extension

We need to load the btree-gist extension, which is needed for showing changesets on the history tab.

For PostgreSQL < 9.1 (change the version number in the path as necessary):

```
psql -d openstreetmap < /usr/share/postgresql/9.0/contrib/btree_gist.sql
```

For PostgreSQL >= 9.1:

```
psql -d openstreetmap -c "CREATE EXTENSION btree_gist"
```

### PostgreSQL Functions

We need to install special functions into the postgresql databases, and these are provided by a library that needs compiling first.

```
cd db/functions
make libpgosm.so
cd ../..
```

Then we create the functions within each database. We're using `pwd` to substitute in the current working directory, since PostgreSQL needs the full path.

```
psql -d openstreetmap -c "CREATE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4 AS '`pwd`/db/functions/libpgosm', 'maptile_for_point' LANGUAGE C STRICT"
psql -d openstreetmap -c "CREATE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '`pwd`/db/functions/libpgosm', 'tile_for_point' LANGUAGE C STRICT"
psql -d openstreetmap -c "CREATE FUNCTION xid_to_int4(xid) RETURNS int4 AS '`pwd`/db/functions/libpgosm', 'xid_to_int4' LANGUAGE C STRICT"
```

### Database structure

To create all the tables, indexes and constraints, run:

```
bundle exec rake db:migrate
```

## Running the tests

To ensure that everything is set up properly, you should now run:

```
bundle exec rake test
```

This test will take a few minutes, reporting tests run, assertions, and any errors. If you receive no errors, then your installation is successful.

The unit tests may output parser errors related to "Attribute lat redefined." These can be ignored.

### Starting the server

Rails comes with a built-in webserver, so that you can test on your own machine without needing a server. Run

```
bundle exec rails server
```

You can now view the site in your favourite web-browser at `http://localhost:3000/`

Note that the OSM map tiles you see aren't created from your local database - they are just the standard map tiles.

# Configuration

After installing this software, you may need to carry out some [configuration steps](CONFIGURE.md), depending on your tasks.
