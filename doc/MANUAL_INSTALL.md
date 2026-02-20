# Manual Installation Guide

These instructions are based on Ubuntu 24.04 LTS, though the OSMF servers are currently running Debian 12. The instructions also work, with only minor amendments, for all other current Ubuntu releases, Fedora and macOS.

## Prerequisites

Many of the dependencies are managed through the standard Ruby on Rails mechanisms - i.e. Ruby gems specified in the Gemfile and installed using Bundler. Some system packages are also required before you can get the various gems installed.

**Minimum requirements:**
* Ruby 3.2+
* PostgreSQL 13+
* Bundler (see note below about [developer Ruby setup](#ruby-version-manager-optional))
* JavaScript Runtime

## Step 1: Install System Dependencies

### Ubuntu 24.04 LTS

```bash
sudo apt-get update
sudo apt-get install ruby ruby-dev ruby-bundler \
                     libvips-dev libxml2-dev libxslt1-dev \
                     nodejs build-essential git-core \
                     postgresql postgresql-contrib libpq-dev \
                     libsasl2-dev libffi-dev libgd-dev \
                     libarchive-dev libyaml-dev libbz2-dev npm
sudo npm install --global yarn
```

> [!TIP]
> On Ubuntu 24.04, you may need to start PostgreSQL:
>
> ```bash
> sudo systemctl start postgresql.service
> ```

### Fedora

```bash
sudo dnf install ruby ruby-devel rubygem-rdoc rubygem-bundler \
                 rubygems libxml2-devel nodejs gcc gcc-c++ git \
                 postgresql postgresql-server \
                 postgresql-contrib libpq-devel \
                 perl-podlators libffi-devel gd-devel \
                 libarchive-devel libyaml-devel bzip2-devel \
                 nodejs-yarn vips-devel
```

On Fedora, if you didn't already have PostgreSQL installed then create a PostgreSQL instance and start the server:

```bash
sudo postgresql-setup initdb
sudo systemctl start postgresql.service
```

Optionally set PostgreSQL to start on boot:

```bash
sudo systemctl enable postgresql.service
```

### macOS

For macOS, you will need [Xcode Command Line Tools](https://mac.install.guide/commandlinetools/); macOS 14 (Sonoma) or later; and some familiarity with Unix development via the Terminal.

**Installing PostgreSQL:**

* Install Postgres.app from https://postgresapp.com/
* Make sure that you've initialized and started Postgresql from the app (there should be a little elephant icon in your systray).
* Add PostgreSQL to your path, by editing your profile:

```bash
nano ~/.profile
```

and adding:

```bash
export PATH=/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH
```

After this, you may need to start a new shell window, or source the profile again by running `. ~/.profile`.

**Installing other dependencies:**

* Install Homebrew from https://brew.sh/
* Install system dependencies, including Ruby:
```bash
brew install ruby libxml2 gd yarn pngcrush optipng \
             pngquant jhead jpegoptim gifsicle svgo \
             advancecomp vips
```
* Install Bundler: `gem install bundler` (you might need to `sudo gem install bundler` if you get an error about permissions - or see note below about [developer Ruby setup](#ruby-version-manager-optional))

You will need to tell `bundler` that `libxml2` is installed in a Homebrew location. If it uses the system-installed one then you will get errors installing the `libxml-ruby` gem later on.

```bash
bundle config build.libxml-ruby --with-xml2-config=/usr/local/opt/libxml2/bin/xml2-config
```

If you want to run the tests, you need `geckodriver` as well:

```bash
brew install geckodriver
```

> [!NOTE]
> OS X does not have a /home directory by default, so if you are using the GPX functions, you will need to change the directories specified in config/application.yml.

## Step 2: Clone the Repository

The repository is reasonably large (~560MB) and it's unlikely that you'll need the full history. Therefore you can probably do with a shallow clone (~100MB):
```bash
git clone --depth=1 https://github.com/openstreetmap/openstreetmap-website.git
```

If you want to add in the full history later on, perhaps to run `git blame` or `git log`, run `git fetch --unshallow`.

> [!TIP]
> To download the full history from the start, run:
> ```bash
> git clone https://github.com/openstreetmap/openstreetmap-website.git
> ```

## Step 3: Install Application Dependencies

### Ruby gems

We use [Bundler](https://bundler.io/) to manage the rubygems required for the project.

```bash
cd openstreetmap-website
bundle install
```

### Node.js modules

We use [Yarn](https://yarnpkg.com/) to manage the Node.js modules required for the project.

```bash
bundle exec bin/yarn install
```

## Step 4: Prepare Configuration Files

### Local settings file

> [!NOTE]
> This is a workaround. [See issues/2185 for details](https://github.com/openstreetmap/openstreetmap-website/issues/2185#issuecomment-508676026).

```bash
touch config/settings.local.yml
```

### Storage setup

`openstreetmap-website` needs to be configured with an object storage facility - for development and testing purposes you can use the example configuration:

```bash
cp config/example.storage.yml config/storage.yml
```

## Step 5: Database Setup

`openstreetmap-website` uses three databases - one for development, one for testing, and one for production. The database-specific configuration options are stored in `config/database.yml`, which we need to create from the example template.

```bash
cp config/example.database.yml config/database.yml
```

> [!IMPORTANT]
> PostgreSQL is configured to, by default, accept local connections without requiring a username or password. This is fine for development. If you wish to set up your database differently, then you should change the values found in the `config/database.yml` file, and amend the instructions below as appropriate.

### PostgreSQL account setup

We need to create a PostgreSQL role (i.e. user account) for your current user, and it needs to be a superuser so that we can create more databases.

```bash
sudo -u postgres -i
createuser -s <username>
exit
```

### Create the databases

To create the three databases - for development, testing and production - run:

```bash
bundle exec rails db:create
```

### Database structure

To create all the tables, indexes and constraints, run:

```bash
bundle exec rails db:migrate
```

## Validate Your Installation

### Running the tests

To ensure that everything is set up properly, you should now run:

```bash
bundle exec rails test:all
```

This test will take a few minutes, reporting tests run, assertions, and any errors. If you receive no errors, then your installation is successful.

> [!NOTE]
> The unit tests may output parser errors related to "Attribute lat redefined." These can be ignored.

### Starting the server

Rails comes with a built-in webserver, so that you can test on your own machine without needing a server. Run

```bash
bundle exec rails server
```

You can now view the site in your favourite web-browser at [http://localhost:3000/](http://localhost:3000/)

> [!NOTE]
> The OSM map tiles you see aren't created from your local database - they are the production map tiles, served from a separate service over the Internet.

## What's Next?

🎉 **Congratulations!** You have successfully installed the OpenStreetMap website.

**Next steps:**
* **Configuration:** See [CONFIGURE.md](CONFIGURE.md) for populating the database with data, creating users, setting up OAuth, and other configuration tasks.
* **Contributing:** Check out [CONTRIBUTING.md](../CONTRIBUTING.md) for coding style guidelines, testing procedures, and how to submit your contributions.

## Ruby Version Manager (Optional)

For simplicity, this document explains how to install all the website dependencies as "system" dependencies. While this can be simpler and faster, you might want more control over the process or the ability to install multiple different versions of Ruby alongside each other.

Several tools exist that allow managing multiple different Ruby versions on the same computer. They also provide the additional advantage that the installs are all in your home directory, so you don't need administrator permissions. These tools are typically known as "version managers".

This section shows how to install Ruby and Bundler with [`rbenv`](https://github.com/rbenv/rbenv), which is one of these tools. If you choose to install Ruby and Bundler via `rbenv`, then you do not need to install the system libraries for Ruby:

* For Ubuntu, you do not need to install the following packages: `ruby ruby-dev ruby-bundler`,
* For Fedora, you do not need to install the following packages: `ruby ruby-devel rubygem-rdoc rubygem-bundler rubygems`
* For macOS, you do not need to `brew install ruby`

> [!IMPORTANT]
> On macOS, make sure you've installed a version of Ruby using `rbenv` before running `gem install bundler`!

After installing a version of Ruby with `rbenv` (the latest stable version is a good place to start), you will need to make that the default. From inside the `openstreetmap-website` directory, run:

```bash
rbenv local $VERSION
```

Where `$VERSION` is the version you installed. You can see a list of available versions by running `rbenv versions`. Then install bundler:

```bash
gem install bundler
```

You should now be able to proceed with the rest of the installation. If you're on macOS, make sure you set up the [config override for the libxml2 location](#macos-click-to-expand) _after_ installing bundler.
