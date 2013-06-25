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

This test will take a few minutes, reporting tests run, assertions, and errors.

'''Note:''' This process may output a parser error related to "Attribute lat redefined." Installation appears to succeed in spite of this.

### Starting the server

Rails comes with a built-in webserver, so that you can test on your own machine without needing a server. Run

```
bundle exec rails server
```

You can now view the site in your favourite web-browser at `http://localhost:3000/`

Note that the OSM map tiles you see aren't created from your local database - they are just the standard map tiles.

## Populating the database

Your installation comes with no geographic data loaded. You can either create new data using one of the editors (Potlatch 2, iD, JOSM etc) or by loading an OSM extract.

* Use this [yet-to-be-written script](https://github.com/openstreetmap/openstreetmap-website/issues/282)

## Managing Users

If you create a user by signing up to your local website, you need to confirm the user before you can log in, which normally happens by clicking a link sent via email. If don't want to set up your development box to send emails to public email addresses then you can create the user as normal and then confirm it manually through the Rails console:

```
$ bundle exec rails console
>> user = User.find_by_display_name("My New User Name")
=> #[ ... ]
>> user.status = "active"
=> "active"
>> user.save!
=> true
>> quit
```

### Giving Administrator/Moderator Permissions

To give administrator or moderator permissions:

```
$ rails console
>> user = User.find_by_display_name("My New User Name")
=> #[ ... ]
>> user.roles.create( {:role => "administrator", :granter_id => user.id}, :without_protection => true)
=> #[ ... ]
>> user.roles.create( {:role => "moderator", :granter_id => user.id}, :without_protection => true)
=> #[ ... ]
>> user.save!
=> true
>> quit
```

## OAuth Consumer Keys

Three of the built-in applications communicate via the API, and therefore need OAuth consumer keys configured. These are:

* Potlatch 2
* iD
* The website itself (for the Notes functionality)

For example, to use the Potlatch 2 editor you need to register it as an OAuth application.

Do the following:
* Log into your Rails Port instance - e.g. http://localhost:3000
* Click on your user name to go to your user page
* Click on "my settings" on the user page
* Click on "oauth settings" on the My settings page
* Click on 'Register your application'.
* Unless you have set up alternatives, use Name: "Local Potlatch" and URL: "http://localhost:3000"
* Check the 'modify the map' box.
* Everything else can be left with the default blank values.
* Click the "Register" button
* On the next page, copy the "consumer key"
* Edit config/application.yml in your rails tree
* Uncomment and change the "potlatch2_key" configuration value
* Restart your rails server

An example excerpt from application.yml:

```
# Default editor
default_editor: "potlatch2"
# OAuth consumer key for Potlatch 2
potlatch2_key: "8lFmZPsagHV4l3rkAHq0hWY5vV3Ctl3oEFY1aXth"
```

Follow the same process for registering and configuring iD (`id_key`) and the website/Notes (`oauth_key`), or to save time, simply reuse the same consumer key for each.

*Note:* The first time Potlatch is run, you will get the following message: "Potlatch 2 has not been configured - please see http://wiki.openstreetmap.org/wiki/The_Rails_Port#Potlatch_2 for more information." Just click "OK" and proceed.

TODO: really? If so, this seems like a bug that needs fixing.

*Note:* Potlatch does not have the appropriate icons if these instructions are followed.

TODO: really? If so, this also seems like a bug that needs fixing.

## Troubleshooting

Rails has its own log.  To inspect the log, do this:

```
 tail -f <path-to-osm-source>/log/development.log
```

If you have more problems, please ask on the [rails-dev@openstreetmap.org mailing list](http://lists.openstreetmap.org/listinfo/rails-dev) or on the [#osm-dev IRC Channel](http://wiki.openstreetmap.org/wiki/IRC)

### Maintaining your installation

If your installation stops working for some reason:

* Sometimes gem dependencies change. To update go to your rails_port directory and run ''bundle install'' as root.

* The OSM database schema is changed periodically and you need to keep up with these improvements. Go to your rails_port directory and run:

```
  rake db:migrate
```

## Testing on the osm dev server

For example, after developing a patch for the rails_port, you might want to demonstrate it to others or ask for comments and testing. To do this one can [set up an instance of the rails_port on the dev server in ones user directory](http://wiki.openstreetmap.org/wiki/Using_the_dev_server#Rails_Applications).

# Contributing

For information on contributing changes to the codes, see [CONTRIBUTING.md](CONTRIBUTING.md)

# Production Deployment

If you want to deploy The Rails Port for production use, you'll need to make a few changes.

* It's not recommended to use `rails server` in production. Our recommended approach is to use [Phusion Passenger](https://www.phusionpassenger.com/).
* Passenger will, by design, use the Production environment and therefore the production database - make sure it contains the appropriate data and user accounts.
* Your production database will also need the extensions and functions installed - see above for details.
* The included version of the map call is quite slow and eats a lot of memory. You should consider using [CGIMap](https://github.com/zerebubuth/openstreetmap-cgimap) instead.
* The included version of the GPX importer is slow and/or completely inoperable. You should consider using [the high-speed GPX importer](http://git.openstreetmap.org/gpx-import.git/).
