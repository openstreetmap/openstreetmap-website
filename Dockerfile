FROM ruby:2.5

# Add yarn apt repository
# https://classic.yarnpkg.com/en/docs/install#debian-stable
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# Install system packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      build-essential \
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
      default-jre-headless \
      phantomjs \
      postgresql-client \
      ruby-dev \
      yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install current Osmosis
RUN curl -OL https://github.com/openstreetmap/osmosis/releases/download/0.47.2/osmosis-0.47.2.tgz && \
    tar -C /usr/local -xzf osmosis-0.47.2.tgz

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install Ruby packages
ADD Gemfile Gemfile.lock /app/
RUN bundle install

# Install NodeJS packages
ADD package.json yarn.lock /app/
RUN yarn
