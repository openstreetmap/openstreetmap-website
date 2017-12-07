# Installation

These instructions are designed for setting up The Rails Port for development and testing.
If you want to deploy the software for your own project, then see the notes at the end.

You can install the software directly on your machine, which is the traditional and probably best-supported approach. However, there is an alternative which may be easier: Vagrant. This installs the software into a virtual machine, which makes it easier to get a consistent development environment and may avoid installation difficulties. For Vagrant instructions, see [VAGRANT.md](VAGRANT.md).

These instructions are based on Ubuntu 12.04 LTS, which is the platform used by the OSMF servers.
The instructions also work, with only minor amendments, for all other current Ubuntu releases, Fedora and MacOSX

We don't recommend attempting to develop or deploy this software on Windows. If you need to use Windows, then try developing this software using Ubuntu in a virtual machine, or use [Vagrant](VAGRANT.md).

## Dependencies

Many of the dependencies are managed through the standard Ruby on Rails mechanisms -
i.e. ruby gems specified in the Gemfile and installed using bundler. However, there are a large number
of packages required before you can get the various gems installed.

## Minimum requirements

* Ruby 2.3
* RubyGems 1.3.1+
* PostgreSQL 9.1+
* ImageMagick
* Bundler
* Javascript Runtime

These can be installed on Ubuntu 16.04 or later with:

```
sudo apt-get install ruby2.3 libruby2.3 ruby2.3-dev \
                     libmagickwand-dev libxml2-dev libxslt1-dev nodejs \
                     apache2 apache2-dev build-essential git-core \
                     postgresql postgresql-contrib libpq-dev postgresql-server-dev-all \
                     libsasl2-dev imagemagick
sudo gem2.3 install bundler
```

### Alternative platforms

#### Fedora

For Fedora, you can install the minimum requirements with:

```
sudo yum install ruby ruby-devel rubygem-rdoc rubygem-bundler rubygems \
                 libxml2-devel js \
                 gcc gcc-c++ git \
                 postgresql postgresql-server postgresql-contrib postgresql-devel \
                 perl-podlators ImageMagick
```

If you didn't already have PostgreSQL installed then create a PostgreSQL instance and start the server:

```
sudo postgresql-setup initdb
sudo systemctl start postgresql.service
```

Optionally set PostgreSQL to start on boot:

```
sudo systemctl enable postgresql.service
```

#### MacOSX

For MacOSX, you will need XCode installed from the Mac App Store; OS X 10.7 (Lion) or later; and some familiarity with Unix development via the Terminal.

Installing PostgreSQL:

* Install Postgres.app from http://postgresapp.com/
* Add PostgreSQL to your path, by editing your profile:

`nano ~/.profile`

and adding:

`export PATH=/Applications/Postgres.app/Contents/MacOS/bin:$PATH`

Installing other dependencies:

* Install Homebrew from http://mxcl.github.io/homebrew/
* Install the latest version of Ruby: `brew install ruby`
* Install ImageMagick: `brew install imagemagick`
* Install libxml2: `brew install libxml2 --with-xml2-config`
* Install Bundler: `gem install bundler`

Note that OS X does not have a /home directory by default, so if you are using the GPX functions, you will need to change the directories specified in config/application.yml.

## Cloning the repository

The repository is reasonably large (~150MB) and it's unlikely that you need the full history. If you are happy to wait for it all to download, run:

```
git clone https://github.com/openstreetmap/openstreetmap-website.git
```

To clone only the most recent version (~23MB), instead use a 'shallow clone':

```
git clone --depth=1 https://github.com/openstreetmap/openstreetmap-website.git
```

If you want to add in the full history later on, perhaps to run `git blame` or `git log`, run `git fetch --depth=1000000`


## Ruby gems

We use [Bundler](http://gembundler.com/) to manage the rubygems required for the project.

```
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

We need to create a PostgreSQL role (i.e. user account) for your current user, and it needs to be a superuser so that we can create more databases.

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

We need to load the `btree-gist` extension, which is needed for showing changesets on the history tab.

```
psql -d openstreetmap -c "CREATE EXTENSION btree_gist"
```

### PostgreSQL Functions

We need to install special functions into the PostgreSQL databases, and these are provided by a library that needs compiling first.

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
bundle exec rake test:db
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
