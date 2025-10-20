# Installation

These instructions are designed for setting up `openstreetmap-website` development environment. If you want to deploy the software for your own project, then see the [Production Deployment Notes](#production-deployment-notes).

## Installation Options

There is more than one way to set up a development environment.

### Containerized Installation

We offer a containerized environment with Docker which may avoid installation difficulties.

To install with Docker, see [DOCKER_INSTALL.md](DOCKER_INSTALL.md).

### Manual Installation

Install dependencies directly on your machine (traditional approach, covered in this guide). This gives you the most control and is often preferred by experienced developers on Linux systems.

> [!WARNING]
> **Windows Note:** We don't recommend using this approach on Windows, as some Ruby gems may not be supported. If you are using Windows, we recommend containerized setup using [Docker](DOCKER.md).

To install manually, see [MANUAL_INSTALL.md](MANUAL_INSTALL.md).

## Production Deployment Notes

> [!WARNING]
> Production deployment requires careful configuration and is significantly different from development setup.

If you want to deploy `openstreetmap-website` for production use, you'll need to make a few changes:

> [!IMPORTANT]
> It's not recommended to use `rails server` in production. Our recommended approach is to use [Phusion Passenger](https://www.phusionpassenger.com/). Instructions are available for [setting it up with most web servers](https://www.phusionpassenger.com/documentation_and_support#documentation).

* Passenger will, by design, use the Production environment and therefore the production database - make sure it contains the appropriate data and user accounts.

> [!TIP]
> The included version of the map call is quite slow and eats a lot of memory. You should consider using [CGIMap](https://github.com/zerebubuth/openstreetmap-cgimap) instead.

* Make sure you generate the i18n files and precompile the production assets: `RAILS_ENV=production bundle exec i18n export; bundle exec rails assets:precompile`
* Make sure the web server user as well as the rails user can read, write and create directories in `tmp/`.
