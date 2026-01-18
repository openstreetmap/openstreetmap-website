<!-- Copilot / AI agent instructions for contributors working on openstreetmap-website -->

# Purpose

Short, actionable guidance to help an AI coding agent be productive in this codebase.

# Quick start (commands)
- Bootstrap a dev environment: `bin/setup` (idempotent; runs `bin/dev` unless `--skip-server`).
- Start the app: `bin/dev` (executes `bin/rails server`).
- Install JS deps: `yarn install` (see `package.json`).
- Install Ruby gems: `bundle install` (the repo uses `Gemfile`).
- Database prepare: `bin/rails db:prepare` (or `bin/rails db:reset` for a full reset).
- Run tests: `bin/rails test` or `bundle exec rails test`.
- Lint/security checks: `bundle exec rubocop`, `bundle exec brakeman`.

# Big-picture architecture (what to know first)
- This is a Ruby on Rails application (Rails ~8.1) that contains:
  - The public web site (controllers under `app/controllers/`, views in `app/views/`).
  - A REST API (routes under `config/routes.rb`), including an `api/0.6` namespace for the editing API.
  - GPX/traces handling, map browsing and external service integrations.
- Key files to inspect for flow & responsibilities:
  - Routes and endpoints: `config/routes.rb` (huge — use it to map URL → controller).
  - Web-wide behaviour and CSP helpers: `app/controllers/application_controller.rb` (CSP macros like `allow_thirdparty_images`, Settings-based offline/read-only checks).
  - API behaviour: `app/controllers/api_controller.rb` (skips CSRF, sets Accept handling, wraps API timeouts, uses Doorkeeper for OAuth).
  - Runtime configuration: `config/settings.yml` and optional `settings.local.yml` (many runtime flags and external service URLs live here).

# Project-specific conventions & patterns
- Global configuration uses the `config` gem — access runtime values via `Settings` (e.g. `Settings.status`, `Settings.nominatim_url`).
- Content-Security-Policy is managed via class helpers in `ApplicationController` (look for `allow_*` class methods when adding CSP rules).
- API controllers follow a different lifecycle than web controllers:
  - They `skip_before_action :verify_authenticity_token` and use `doorkeeper` tokens for auth.
  - Format negotiation is explicit in `ApiController#set_request_formats` (Accept header fallback to XML).
- Routes: many legacy and compatibility routes exist (redirects, multiple resource definitions). Prefer changing behaviour in the specific controller handling the route.
- JS/CSS pipeline: Ruby-side asset pipeline plus external JS packages managed in `package.json` — run `yarn install` when editing front-end code.

# Integration points & external dependencies (must be configured to run features)
- External services used via settings in `config/settings.yml`: `nominatim_url`, `overpass_url`, `maptiler_key`, routing services (`graphhopper_url`, `fossgis_osrm_url`), MaxMind GeoIP, S3 (`aws-sdk-s3`) if using remote storage.
- OAuth: Doorkeeper is used (`use_doorkeeper` in routes). See `config/settings.yml` keys for `doorkeeper_signing_key`.
- Background jobs: `delayed_job_active_record` is included; some flows rely on job processing in production.
- Database-level logic: `db/structure.sql` and `lib/database_functions.rb` — functions and SQL may be relied on by the application.

# Developer workflows & tests
- Use `bin/setup` to prepare a dev environment (installs gems, runs `bin/rails db:prepare`, clears tmp/logs).
- To run a single controller test: `bin/rails test test/controllers/some_controller_test.rb`.
- System tests and JS-driven features use Capybara/Selenium — running them may require a browser driver and X virtual framebuffer or CI environment.
- CI runs lint and test workflows (see `README.md` badges). Reproduce locally with `bundle exec rubocop` and `bin/rails test`.

# Where to look for common tasks or examples
- Authentication flows: `app/controllers/sessions_controller.rb`, `app/controllers/users_controller.rb` and Doorkeeper controllers under `app/controllers/oauth2_*`.
- API implementations: controller folders under `app/controllers/api/` and routing under `config/routes.rb` (`namespace :api, path: "api/0.6"`).
- Helpers & business logic: `lib/` for mapping, OSM-specific helpers (e.g. `lib/osm.rb`, `lib/map_layers.rb`).
- Front-end assets & localization: `package.json`, `app/assets/javascripts/`, `config/locales/` and `config/i18n.js.erb`.

# Editing notes for AI agents
- Keep changes minimal and local: update the controller, model, or view tied to the route — `config/routes.rb` is authoritative for URL → code mapping.
- When changing runtime behaviour, prefer adding a `Settings` key in `config/settings.yml` and reading via `Settings` rather than hard-coding.
- Follow existing CSP helper patterns in `ApplicationController` when adding new host/script/style allowances.
- For API changes, mirror existing `ApiController` patterns (format negotiation, `api_call_timeout`, `api_call_handle_error`) to maintain consistent error handling.

# Example quick edit cycle
1. Edit code in `app/controllers/...` or `app/models/...`.
2. Run the relevant unit test: `bin/rails test test/controllers/your_file_test.rb`.
3. Run a focused lint: `bundle exec rubocop app/controllers/your_controller.rb`.
4. If JS changed: `yarn install` then reload dev server.

# Docker (when using Docker setup)
- The repository includes a `docker-compose.yml` with two services: `web` (Rails app) and `db` (Postgres). The host maps ports `3000` → `web:3000` and `54321` → `db:5432`.
- Preferred workflow is to build images and run commands through `docker compose`. Examples below assume you are in the repository root.

Build images:
```bash
docker compose build
```

Start services (db first if you want background DB only):
```bash
docker compose up -d db
# then start app
docker compose up -d web
```

Run the standard setup inside a throwaway `web` container (avoids starting the server inside the container):
```bash
docker compose run --rm web bin/setup --skip-server
```

Run migrations, prepare test DB, and run tests from inside Docker:
```bash
docker compose run --rm web bundle exec rails db:migrate
docker compose run --rm web bundle exec rails db:test:prepare
docker compose run --rm web bundle exec rails test
```

Install JS deps inside the container (if needed):
```bash
docker compose run --rm web yarn install
```

Exec into a running `web` container for interactive debugging or one-off commands:
```bash
docker compose exec web bash
# inside container
bundle exec rails console
```

Notes:
- Use `docker compose run --rm web` for ephemeral one-off commands (tests, migrations, setup).
- Use `docker compose exec web` to attach to an already-running `web` container (keeps server running).
- The repo is mounted into `/app` inside the `web` container; changes on host are visible in the container.

