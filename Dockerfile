FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list \
 && sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# Install system packages then clean up to minimize image size
RUN apt-get update \
 && apt-get install --no-install-recommends -y \
      build-essential \
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
      nodejs \
      npm \
 && npm install --global yarn \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=dialog

# Setup app location
COPY ./ /app
WORKDIR /app

# Install Ruby packages
RUN gem sources -r https://rubygems.org/ -a https://gems.ruby-china.com/ \
 && bundle config mirror.https://rubygems.org https://gems.ruby-china.com \
 && bundle install

# Install NodeJS packages using yarn
RUN bundle exec bin/yarn install
