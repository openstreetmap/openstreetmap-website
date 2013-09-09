# Configuration

After [installing](INSTALL.md) this software, you may need to carry out some of these configuration steps, depending on your tasks.

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
$ bundle exec rails console
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

## Troubleshooting

Rails has its own log.  To inspect the log, do this:

```
tail -f log/development.log
```

If you have more problems, please ask on the [rails-dev@openstreetmap.org mailing list](http://lists.openstreetmap.org/listinfo/rails-dev) or on the [#osm-dev IRC Channel](http://wiki.openstreetmap.org/wiki/IRC)

## Maintaining your installation

If your installation stops working for some reason:

* Sometimes gem dependencies change. To update go to your rails_port directory and run ''bundle install'' as root.

* The OSM database schema is changed periodically and you need to keep up with these improvements. Go to your rails_port directory and run:

```
bundle exec rake db:migrate
```

## Testing on the osm dev server

For example, after developing a patch for the rails_port, you might want to demonstrate it to others or ask for comments and testing. To do this one can [set up an instance of the rails_port on the dev server in ones user directory](http://wiki.openstreetmap.org/wiki/Using_the_dev_server#Rails_Applications).

# Contributing

For information on contributing changes to the codes, see [CONTRIBUTING.md](CONTRIBUTING.md)

# Production Deployment

If you want to deploy The Rails Port for production use, you'll need to make a few changes.

* It's not recommended to use `rails server` in production. Our recommended approach is to use [Phusion Passenger](https://www.phusionpassenger.com/).
* Passenger will, by design, use the Production environment and therefore the production database - make sure it contains the appropriate data and user accounts.
* Your production database will also need the extensions and functions installed - see [INSTALL.md](INSTALL.md)
* The included version of the map call is quite slow and eats a lot of memory. You should consider using [CGIMap](https://github.com/zerebubuth/openstreetmap-cgimap) instead.
* The included version of the GPX importer is slow and/or completely inoperable. You should consider using [the high-speed GPX importer](http://git.openstreetmap.org/gpx-import.git/).
