FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages then clean up to minimize image size
RUN apt-get update \
 && apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      default-jre-headless \
      file \
      firefox-geckodriver \
      imagemagick \
      libarchive-dev \
      libffi-dev \
      libgd-dev \
      libmagickwand-dev \
      libpq-dev \
      libsasl2-dev \
      libxml2-dev \
      libxslt1-dev \
      locales \
      nodejs \
      postgresql-client \
      ruby2.7 \
      libruby2.7 \
      ruby2.7-dev \
      tzdata \
      unzip \
      libbz2-dev \
      yarnpkg \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install compatible Osmosis to help users import sample data in a new instance
# RUN curl -OL https://github.com/openstreetmap/osmosis/releases/download/0.47.2/osmosis-0.47.2.tgz \
#  && tar -C /usr/local -xzf osmosis-0.47.2.tgz

# Install bundler
RUN gem2.7 install bundler

ENV DEBIAN_FRONTEND=dialog

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install Ruby packages
ADD Gemfile Gemfile.lock /app/
RUN bundle install

# Install NodeJS packages using yarnpkg
# `bundle exec rake yarn:install` will not work
ADD package.json yarn.lock Rakefile config /app/
RUN yarnpkg install
RUN set RAILS_ENV=production
RUN bundle exec rake i18n:js:export assets:precompile
