FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      default-jre-headless \
      firefox-geckodriver \
      imagemagick \
      libarchive-dev \
      libffi-dev \
      libmagickwand-dev \
      libpq-dev \
      libsasl2-dev \
      libxml2-dev \
      libxslt1-dev \
      locales \
      nodejs \
      postgresql-client \
      ruby2.7 \
      ruby2.7-dev \
      tzdata \
      yarnpkg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install current Osmosis
RUN curl -OL https://github.com/openstreetmap/osmosis/releases/download/0.47.2/osmosis-0.47.2.tgz && \
    tar -C /usr/local -xzf osmosis-0.47.2.tgz

ENV DEBIAN_FRONTEND=dialog

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install Ruby packages
ADD Gemfile Gemfile.lock /app/
RUN gem install bundler && \
    bundle install

# Install NodeJS packages
ADD package.json yarn.lock /app/
RUN yarnpkg install
