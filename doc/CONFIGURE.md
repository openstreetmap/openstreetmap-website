# Configuration

After [installing](INSTALL.md) the OpenStreetMap website, you may need to carry out some configuration steps depending on your development tasks.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Basic Application Configuration](#basic-application-configuration)
3. [Database Population](#database-population)
4. [User Management](#user-management)
5. [OAuth Setup](#oauth-setup)
6. [Development Tools](#development-tools)
7. [Production Deployment](#production-deployment)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

Before proceeding with configuration, ensure you have:
- Completed the [installation steps](INSTALL.md)
- Successfully started the Rails server
- Verified the website loads at [http://localhost:3000](http://localhost:3000)

## Basic Application Configuration

### Application Settings

Many settings are available in `config/settings.yml`. You can customize your installation of `openstreetmap-website` by overriding these values using `config/settings.local.yml`.

## Database Population

Your installation comes with no geographic data loaded. Before adding any data using one of the editors (iD, JOSM etc), you can optionally prepopulate the database using an OSM extract.

### Loading Data with Osmosis (Optional)

> [!NOTE]
> This step is entirely optional. You can start using the editors immediately to create new data, or if you prefer to work with existing data, you can import an extract with [Osmosis](https://wiki.openstreetmap.org/wiki/Osmosis) and the [`--write-apidb`](https://wiki.openstreetmap.org/wiki/Osmosis/Detailed_Usage#--write-apidb_.28--wd.29) task.

To import an extract, run:

```bash
osmosis --read-pbf greater-london-latest.osm.pbf \
  --write-apidb host="localhost" database="openstreetmap" \
  user="openstreetmap" password="" validateSchemaVersion="no"
```

> [!IMPORTANT]
> - Loading an apidb database with Osmosis is about **twenty** times slower than loading the equivalent data with osm2pgsql into a rendering database
> - [`--log-progress`](https://wiki.openstreetmap.org/wiki/Osmosis/Detailed_Usage#--log-progress_.28--lp.29) may be desirable for status updates
> - To be able to edit the data you have loaded, you will need to use this [yet-to-be-written script](https://github.com/openstreetmap/openstreetmap-website/issues/282)

## User Management

After creating a user through the web interface at [http://localhost:3000/user/new](http://localhost:3000/user/new), you may need to perform additional user management tasks.

> [!TIP]
> If you don't want to set up your development box to send emails, you can manually confirm users and grant permissions through the Rails console.

### Managing Users via Rails Console

1. **Enter the Rails console:**
   ```bash
   $ bundle exec rails console
   ```

2. **Find the user:**
   ```ruby
   >> user = User.find_by(:display_name => "My New User Name")
   => #[ ... ]
   ```

3. **Modify the user as desired:**

   **Activate/confirm the user:**
   ```ruby
   >> user.activate!
   => true
   ```

   **Grant moderator role:**
   ```ruby
   >> user.roles.create(:role => "moderator", :granter_id => user.id)
   => #[ ... ]
   ```

   **Grant administrator role:**
   ```ruby
   >> user.roles.create(:role => "administrator", :granter_id => user.id)
   => #[ ... ]
   ```

4. **Exit the Rails console:**
   ```ruby
   >> quit
   ```

## OAuth Setup

There are two built-in applications which communicate via the API, and therefore need to be registered as OAuth 2 applications. These are:

* **iD** - the web-based editor
* **The website itself** - for the Notes functionality

You need to register these applications with *one* of the users you created. After that iD and Notes functionality becomes available to every user of the website.

### Automated OAuth Setup (Recommended)

> [!TIP]
> You can register both applications automatically by running the following rake task:
>
> ```bash
> bundle exec rails oauth:register_apps["My New User Name"]
> ```
>
> This task registers the applications with the "My New User Name" user as the owner and saves their keys to `config/settings.local.yml`. When logged in, the owner should be able to see the apps on the OAuth 2 applications page.

Alternatively you can register the applications manually, as described in the next section.

### Setting up OAuth for iD

1. **Navigate to OAuth applications:**
   - Go to "[OAuth 2 applications](http://localhost:3000/oauth2/applications)" on the My Account page

2. **Register new application:**
   - Click on "Register new application"
   - **Name:** "Local iD"
   - **Redirect URIs:** "http://localhost:3000" (unless you have set up alternatives)

3. **Select permissions:**
   Check boxes for the following:
   - ✅ 'Read user preferences'
   - ✅ 'Modify user preferences'
   - ✅ 'Modify the map'
   - ✅ 'Read private GPS traces'
   - ✅ 'Upload GPS traces'
   - ✅ 'Modify notes'

4. **Configure the application:**
   - Copy the "Client ID" from the next page
   - Edit `config/settings.local.yml` in your rails tree
   - Add the "id_application" configuration with the "Client ID" as the value
   - Restart your rails server

> [!TIP]
> **Example configuration in `settings.local.yml`:**
> ```yaml
> # Default editor
> default_editor: "id"
> # OAuth 2 Client ID for iD
> id_application: "Snv…OA0"
> ```

### Setting up OAuth for Notes and Changeset Discussions

To allow [Notes](https://wiki.openstreetmap.org/wiki/Notes) and changeset discussions to work:

1. **Register OAuth application for the website:**
   - Go to "[OAuth 2 applications](http://localhost:3000/oauth2/applications)" on the My Account page
   - Click on "Register new application"
   - **Name:** "OpenStreetMap Web Site"
   - **Redirect URIs:** "http://localhost:3000"

2. **Select permissions:**
   Check boxes for:
   - ✅ 'Modify the map'
   - ✅ 'Modify notes'

3. **Configure the application:**
   - Copy both the "Client Secret" and "Client ID"
   - Edit `config/settings.local.yml`
   - Add both configurations
   - Restart your rails server

> [!TIP]
> **Example configuration in `settings.local.yml`:**
> ```yaml
> # OAuth 2 Client ID for the web site
> oauth_application: "SGm8QJ6tmoPXEaUPIZzLUmm1iujltYZVWCp9hvGsqXg"
> # OAuth 2 Client Secret for the web site
> oauth_key: "eRHPm4GtEnw9ovB1Iw7EcCLGtUb66bXbAAspv3aJxlI"
> ```

## Development Tools

### Viewing Rails Logs

Rails has its own log. To inspect the log during development:

```bash
tail -f log/development.log
```

### Email Previews

We use [ActionMailer Previews](https://guides.rubyonrails.org/action_mailer_basics.html#previewing-and-testing-mailers) to generate previews of the emails sent by the application. Visit [http://localhost:3000/rails/mailers](http://localhost:3000/rails/mailers) to see the list of available previews.

### Maintaining Your Installation

> [!TIP]
> If your installation stops working for some reason:
>
> - **Update gems:** Sometimes the bundle has been updated. Go to your `openstreetmap-website` directory and run:
>   ```bash
>   bundle install
>   ```
>
> - **Update Node.js modules:** If Node.js modules have been updated, run:
>   ```bash
>   bundle exec bin/yarn install
>   ```
>
> - **Run database migrations:** The OSM database schema is changed periodically. To keep up with improvements:
>   ```bash
>   bundle exec rails db:migrate
>   ```

## Production Deployment

If you want to deploy `openstreetmap-website` for production use, you'll need to make several changes:

### Web Server Configuration

> [!WARNING]
> Don't use `rails server` in production. Our recommended approach is to use [Phusion Passenger](https://www.phusionpassenger.com/).

- Instructions are available for [setting it up with most web servers](https://www.phusionpassenger.com/documentation_and_support#documentation)
- Passenger will, by design, use the Production environment and therefore the production database - make sure it contains the appropriate data and user accounts

### Performance Optimizations

> [!TIP]
> **Consider using CGIMap:** The included version of the map call is quite slow and eats a lot of memory. You should consider using [CGIMap](https://github.com/zerebubuth/openstreetmap-cgimap) instead.

### Asset Compilation

- **Generate i18n files and precompile assets:**
  ```bash
  RAILS_ENV=production bundle exec i18n export
  bundle exec rails assets:precompile
  ```

### File Permissions

> [!IMPORTANT]
> Make sure the web server user as well as the rails user can read, write and create directories in `tmp/`.

### Testing on the OSM Dev Server

For example, after developing a patch for `openstreetmap-website`, you might want to demonstrate it to others or ask for comments and testing. To do this you can [set up an instance of openstreetmap-website on the dev server in your user directory](https://wiki.openstreetmap.org/wiki/Using_the_dev_server#Rails_Applications).

## Troubleshooting

If you have problems with your configuration:

- **Check the Rails log:** Use `tail -f log/development.log` to see what's happening
- **Verify database connectivity:** Ensure PostgreSQL is running and accessible
- **Check file permissions:** Make sure the Rails application can read/write necessary files
- **Review OAuth settings:** Ensure Client IDs and secrets are correctly configured

### Getting Help

If you need additional assistance:
- **Mailing list:** Ask on the [rails-dev@openstreetmap.org mailing list](https://lists.openstreetmap.org/listinfo/rails-dev)
- **IRC:** Join the [#osm-dev IRC Channel](https://wiki.openstreetmap.org/wiki/IRC)

## Contributing

For information on contributing changes to the code, see [CONTRIBUTING.md](../CONTRIBUTING.md)
