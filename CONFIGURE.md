# Configuration

After [installing](INSTALL.md) this software, you may need to carry out some of these configuration steps, depending on your tasks.

## Application configuration

Many settings are available in `config/settings.yml`. You can customize your installation of The Rails Port by overriding these values using `config/settings.local.yml`

## Populating the database

Your installation comes with no geographic data loaded. You can either create new data using one of the editors (Potlatch 2, iD, JOSM etc) or by loading an OSM extract.

After installing but before creating any users or data, import an extract with [Osmosis](https://wiki.openstreetmap.org/wiki/Osmosis) and the [``--write-apidb``](https://wiki.openstreetmap.org/wiki/Osmosis/Detailed_Usage#--write-apidb_.28--wd.29) task.

```
osmosis --read-pbf greater-london-latest.osm.pbf \
  --write-apidb host="localhost" database="openstreetmap" \
  user="openstreetmap" password="" validateSchemaVersion="no"
```

Loading an apidb database with Osmosis is about **twenty** times slower than loading the equivalent data with osm2pgsql into a rendering database. [``--log-progress``](https://wiki.openstreetmap.org/wiki/Osmosis/Detailed_Usage#--log-progress_.28--lp.29) may be desirable for status updates.

To be able to edit the data you have loaded, you will need to use this [yet-to-be-written script](https://github.com/openstreetmap/openstreetmap-website/issues/282).

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
$ bundle exec rails console
>> user = User.find_by_display_name("My New User Name")
=> #[ ... ]
>> user.roles.create(:role => "administrator", :granter_id => user.id)
=> #[ ... ]
>> user.roles.create(:role => "moderator", :granter_id => user.id)
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
* Edit config/settings.local.yml in your rails tree
* Add the "potlatch2_key" configuration key and the consumer key as the value
* Restart your rails server

An example excerpt from settings.local.yml:

```
# Default editor
default_editor: "potlatch2"
# OAuth consumer key for Potlatch 2
potlatch2_key: "8lFmZPsagHV4l3rkAHq0hWY5vV3Ctl3oEFY1aXth"
```

Follow the same process for registering and configuring iD (`id_key`) and the website/Notes (`oauth_key`), or to save time, simply reuse the same consumer key for each.

## Troubleshooting

Rails has its own log.  To inspect the log, do this:

```
tail -f log/development.log
```

If you have more problems, please ask on the [rails-dev@openstreetmap.org mailing list](https://lists.openstreetmap.org/listinfo/rails-dev) or on the [#osm-dev IRC Channel](https://wiki.openstreetmap.org/wiki/IRC)

## Maintaining your installation

If your installation stops working for some reason:

* Sometimes gem dependencies change. To update go to your rails_port directory and run ''bundle install'' as root.

* The OSM database schema is changed periodically and you need to keep up with these improvements. Go to your rails_port directory and run:

```
bundle exec rake db:migrate
```

## Testing on the osm dev server

For example, after developing a patch for the rails_port, you might want to demonstrate it to others or ask for comments and testing. To do this one can [set up an instance of the rails_port on the dev server in ones user directory](https://wiki.openstreetmap.org/wiki/Using_the_dev_server#Rails_Applications).

# Contributing

For information on contributing changes to the codes, see [CONTRIBUTING.md](CONTRIBUTING.md)

# Production Deployment

If you want to deploy The Rails Port for production use, you'll need to make a few changes.

* It's not recommended to use `rails server` in production. Our recommended approach is to use [Phusion Passenger](https://www.phusionpassenger.com/). Instructions are available for [setting it up with most web servers](https://www.phusionpassenger.com/documentation_and_support#documentation).
* Passenger will, by design, use the Production environment and therefore the production database - make sure it contains the appropriate data and user accounts.
* Your production database will also need the extensions and functions installed - see [INSTALL.md](INSTALL.md)
* The included version of the map call is quite slow and eats a lot of memory. You should consider using [CGIMap](https://github.com/zerebubuth/openstreetmap-cgimap) instead.
* The included version of the GPX importer is slow and/or completely inoperable. You should consider using [the high-speed GPX importer](https://git.openstreetmap.org/gpx-import.git/).
* Make sure you generate the i18n files and precompile the production assets: `RAILS_ENV=production rake i18n:js:export assets:precompile`
* Make sure the web server user as well as the rails user can read, write and create directories in `tmp/`.
* If you want to use diff replication then you will need to install the shared library versions of the special SQL functions (see the bottom of [INSTALL.md](INSTALL.md)).
* If you expect to serve a lot of `/changes` API calls, then you might also want to install the shared library versions of the SQL functions.
