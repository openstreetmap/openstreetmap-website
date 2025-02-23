FROM ruby:3.2-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages then clean up to minimize image size
RUN apt-get update \
  && apt-get install --no-install-recommends -y \
  build-essential \
  curl \
  default-jre-headless \
  file \
  git-core \
  gpg-agent \
  libarchive-dev \
  libffi-dev \
  libgd-dev \
  libpq-dev \
  libsasl2-dev \
  libvips-dev \
  libxml2-dev \
  libxslt1-dev \
  libyaml-dev \
  locales \
  postgresql-client \
  ruby-dev \
  ruby-bundler \
  tzdata \
  unzip \
  nodejs \
  npm \
  osmosis \
  ca-certificates \
  firefox-esr

# Install yarn globally
RUN npm install --global yarn

ENV DEBIAN_FRONTEND=dialog

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install Ruby packages
ADD Gemfile Gemfile.lock /app/
RUN bundle install

# Install NodeJS packages using yarn
ADD package.json yarn.lock /app/
ADD bin/yarn /app/bin/
RUN bundle exec bin/yarn install
