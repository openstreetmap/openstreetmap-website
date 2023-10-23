FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages then clean up to minimize image size
RUN apt-get update \
 && apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      default-jre-headless \
      file \
      gpg-agent \
      libarchive-dev \
      libffi-dev \
      libgd-dev \
      libpq-dev \
      libsasl2-dev \
      libvips-dev \
      libxml2-dev \
      libxslt1-dev \
      locales \
      postgresql-client \
      ruby \
      ruby-dev \
      ruby-bundler \
      software-properties-common \
      tzdata \
      unzip \
      nodejs \
      npm \
 && npm install --global yarn \
 # We can't use snap packages for firefox inside a container, so we need to get firefox+geckodriver elsewhere
 && add-apt-repository -y ppa:mozillateam/ppa \
 && echo "Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001" > /etc/apt/preferences.d/mozilla-firefox \
 && apt-get install --no-install-recommends -y \
      firefox-geckodriver \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install compatible Osmosis to help users import sample data in a new instance
RUN curl -OL https://github.com/openstreetmap/osmosis/releases/download/0.47.2/osmosis-0.47.2.tgz \
 && tar -C /usr/local -xzf osmosis-0.47.2.tgz

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
