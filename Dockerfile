FROM ruby:2.3-slim
MAINTAINER OpenStreetMap
ENV REFRESHED_AT 2016-09-15

# Install packages
RUN apt-get update
RUN apt-get install -y --no-install-recommends build-essential
RUN apt-get install -y --no-install-recommends ruby-dev
RUN apt-get install -y --no-install-recommends libxml2-dev
RUN apt-get install -y --no-install-recommends libxslt1-dev
RUN apt-get install -y --no-install-recommends libpq-dev
RUN apt-get install -y --no-install-recommends libsasl2-dev
RUN apt-get install -y --no-install-recommends imagemagick
RUN apt-get install -y --no-install-recommends libmagickwand-dev
RUN apt-get install -y --no-install-recommends nodejs
RUN apt-get install -y --no-install-recommends file
RUN apt-get install -y --no-install-recommends postgresql-client
RUN apt-get install -y --no-install-recommends locales
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install gems
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install

RUN sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_GB.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_GB.UTF-8

ENV LANG en_GB.UTF-8
