# Installation

These instructions are designed for setting up The Rails Port for development and testing.
If you want to deploy the software for your own project, then see the notes at the end.

## Dependencies

Many of the dependencies are managed through the standard Ruby on Rails mechanisms -
i.e. ruby gems specified in the Gemfile and installed using bundler. However, there are a large number
of packages required to get the various gems installed.

## Minimum requirements

* Ruby 1.8.7 or 1.9.3
* RubyGems 1.3.1+
* Postgres 8.3+
* ImageMagick
* Bundler

### Ubuntu (10.10 or later)

`sudo apt-get install ruby libruby ruby-dev rdoc ri libmagickwand-dev libxml2-dev libxslt1-dev apache2 apache2-threaded-dev build-essential git-core postgresql postgresql-contrib libpq-dev libsasl2-dev openjdk-6-jre postgresql-server-dev-9.1`

TODO - check or remove the postgresql-server-dev-9.1 mention that's on the wiki - it doesn't apply to all ubuntus, and is it needed?
TODO - remove osmosis related instructions in favour of people going reading osmosis stuff on the osmosis wiki pages

### Fedora

TODO

### MacOSX

It's advisable to develop on MacOSX by using Ubuntu in a virtual machine. Otherwise ImageMagick will eat your soul.

### Windows

It's advisable to develop on windows by using Ubuntu in a virtual machine. Otherwise it's a world of hurt


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

### PostgreSQL Btree-gist Extension

We need to load the btree-gist extension # TODO why?

For PostgreSQL < 9.1 (change the version number in the path as necessary):

```
psql -d openstreetmap < /usr/share/postgresql/9.1/contrib/btree_gist.sql
```

For PostgreSQL >= 9.1:

```
psql -d openstreetmap -c "CREATE EXTENSION btree_gist;"
psql -d osm -c "CREATE EXTENSION btree_gist;"
```

TODO: not required for the test database?

### PostgreSQL Quadtile Functions

We need to install special functions into the postgresql databases, and these are provided by a library that needs compiling first.

Ensure that you have the *server* extension headers for PostgreSQL, on Ubuntu the package is typically called postgresql-server-dev-9.1 (or 8.2, or whatever version of PostgreSQL you have installed).

```
sudo apt-get install postgresql-server-dev-X.X
```

Now build the library, found in the `db/functions` directory

```
cd openstreetmap-website/db/functions
make libpgosm.so
```

Then we create the functions within each database. Be sure to replace the "/<your path info>" text with the appropriate full path information.

```
psql -d openstreetmap -c "CREATE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4 AS '/<your path info>/openstreetmap-website/db/functions/libpgosm', 'maptile_for_point' LANGUAGE C STRICT;"
psql -d osm -c "CREATE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4 AS '/<your path info>/openstreetmap-website/db/functions/libpgosm', 'maptile_for_point' LANGUAGE C STRICT;"
psql -d openstreetmap -c "CREATE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '/<your path info>/openstreetmap-website/db/functions/libpgosm', 'tile_for_point' LANGUAGE C STRICT;"
psql -d osm -c "CREATE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '/<your path info>/openstreetmap-website/db/functions/libpgosm', 'tile_for_point' LANGUAGE C STRICT;"
psql -d openstreetmap -c "CREATE FUNCTION xid_to_int4(xid) RETURNS int4 AS '/<your path info>/openstreetmap-website/db/functions/libpgosm', 'xid_to_int4' LANGUAGE C STRICT;"
psql -d osm -c "CREATE FUNCTION xid_to_int4(xid) RETURNS int4 AS '/<your path info>/openstreetmap-website/db/functions/libpgosm', 'xid_to_int4' LANGUAGE C STRICT;"</pre>
```


TODO: Ditch all this, use rake db:create

Now, create the openstreetmap user for the postgres database, using the username and password you put into the configuration files in the prior step. Note that you will be prompted to set the password for the openstreetmap user.

<pre style="white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word">
sudo apt-get install postgresql-contrib libpq-dev
createuser openstreetmap -s -P
  <* enter and confirm the password information *>
createdb -E UTF8 -O openstreetmap openstreetmap
createdb -E UTF8 -O openstreetmap osm_test
createdb -E UTF8 -O openstreetmap osm
</pre>

### Database structure

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

* Use this (yet-to-be-written script)[https://github.com/openstreetmap/openstreetmap-website/issues/282]

## Managing Users

If you create a user and you don't want to set up your development box to send E-Mail to a public E-Mail address then you can create the user in the web UI as normal and then confirm it manually through the Rails console:

```
$ rails console
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

=== Potlatch 2 ===
To use the Potlatch 2 editor you need to register it as an OAuth application.

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
* Change the "potlatch2_key" configuration value - excerpt from application.yml:
<pre>
# Default editor
default_editor: "potlatch2"
# OAuth consumer key for Potlatch 2
potlatch2_key: "8lFmZPsagHV4l3rkAHq0hWY5vV3Ctl3oEFY1aXth"
</pre>

'''Note:''' The first time Potlatch is run, you will get the following message: "Potlatch 2 has not been configured - please see http://wiki.openstreetmap.org/wiki/The_Rails_Port#Potlatch_2 for more information." Just click "OK" and proceed.

'''Note:''' If your attempt to save any ways leads to a hanging "authorisation required" message, flush your browser cache and try again.

'''Note:''' Potlatch does not have the appropriate icons if these instructions are followed.

==Troubleshooting==

Rails has its own log.  To inspect the log, do this:
 tail -f <path-to-osm-source>/log/development.log

If you have more problems, please ask on the [[Contact#Mailing_lists|dev mailing list]] (dev@openstreetmap.org) or on [[Contact#IRC|IRC]]. Here are some frequently encountered issues.

=== Maintaining your installation ===

If your installation stops working for some reason:

* Sometimes gem dependencies change. To update go to your rails_port directory and run ''bundle install'' as root.

* The OSM database schema is changed periodically and you need to keep up with these improvements. Go to your rails_port directory and
  rake db:migrate

===Getting GPX importing to work===

You don't need the GPX import facility to work before using the rest of the Rails port. However, if you want to hack on this bit, too:

* Make sure you have set the database settings for 'production' (config/database.yml) as well as 'development'
* Make sure you have set your SMTP server in config/initializers/action_mailer.rb
* Install the 'daemons' package: gem install daemons
* Create directories at /home/osm/traces and /home/osm/images (you can change these dirs in config/application.yml)
* If your rails config/environment.rb or config/environments/*.rb file specifies 'config.action_controller.perform_caching = true' - which is the default if you are running your rails server in its 'production' environment:
** Create a directory at the path you specified at 'config.cache_store' in 'config/environment.rb' - default: in your rails directory at tmp/cache.
** Also make sure it has the correct permissions (e.g. chown to the user running your rails application.)
** (Otherwise, GPX files will get uploaded but no acknowledgment appears on the return page.)
* Then start the import daemon running: script/daemons start

If you run into trouble, you can turn on logging by adding this line to lib/daemons/gpx_import_ctl

options[:log_output] = true

Logs will then be written in the log dir.

====The high-performance GPX importer====

If you are interested in running the same GPX importer as runs on the main server then you should investigate the GPX importer which is present in the git repository at [http://git.openstreetmap.org/gpx-import.git/tree gpx-import] but requires you to build C code and configure it. See the settings.sh file in that for help on configuring the higher performance GPX importer

== The high-performance map call (cgimap) ==

In addition to the API written in ruby on rails, there is a high-performance implementation of the single API function "map" called [[cgimap]]. It is written in C++ as a fastCGI server and is approximately 10x less CPU intense than the rails version. Both versions should give the identical output and can be tested statistically with the [http://trac.openstreetmap.org/browser/applications/utils/OsmMapCallValidator OsmMapCallValidator].

[[Cgimap/install|Installing cgimap.]]

== Testing on the osm dev server ==

For example, after developing a patch for the rails_port, you might want to demonstrate it to others or ask for comments and testing. To do this one can [[Using_the_dev_server#Rails_Applications|set up an instance of the rails_port on the dev server in ones user directory]].

== Miscellanea ==

It is possible to produce diagrams of the rails port using railroad. More information is in [[/Railroad diagrams]].

To generate the HTML documentation of the API/rails code, run the command rake doc:app

To generate test coverage stats, sudo gem install rcov. Then rcov -x gems test/*/*.rb in the rails_port directory.

Some information about [[/Testing|testing]]. The tests are automatically run on commit with the results shown at http://cruise.openstreetmap.org/

To commit your changes, see [[Rails port/Development]]

Rails-dev OSM maillist: http://lists.openstreetmap.org/listinfo/rails-dev

[[Category:Ruby|Rails Port]]
[[Category:Map API Server|Rails Port]]
[[Category:Software|Rails Port]]

# Production Deployment

Write some notes here about passenger, CGIMap and the GPX importer.