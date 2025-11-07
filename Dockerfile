ARG RUBY_VERSION=3.2
FROM ruby:$RUBY_VERSION-bookworm

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
    tzdata \
    unzip \
    nodejs \
    npm \
    osmosis \
    ca-certificates \
    firefox-esr \
    xvfb \
    mesa-utils \
    libgl1-mesa-dri \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* # Replace with `apt-get dist-clean` after upgrading to Debian 13 (Trixie)

# Install yarn globally
RUN npm install --global yarn

ENV DEBIAN_FRONTEND=dialog

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install Ruby packages
COPY Gemfile Gemfile.lock /app/
RUN bundle install

# Install NodeJS packages using yarn
COPY package.json yarn.lock /app/
COPY bin/yarn /app/bin/
RUN bundle exec bin/yarn install

# Copy and set entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
