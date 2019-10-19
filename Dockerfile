FROM ruby:2.5

# fixes dpkg man page softlink error while installing postgresql-client [source: https://stackoverflow.com/a/52655008/5350059]
RUN mkdir -p /usr/share/man/man1 && \
    mkdir -p /usr/share/man/man7

# npm is not available in Debian repo so following official instruction [source: https://github.com/nodesource/distributions/blob/master/README.md#debinstall]
RUN curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh && \
    bash nodesource_setup.sh && \
    rm -f nodesource_setup.sh

# install packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
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
      osmosis \
      postgresql-client \
      ruby-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install npm packages
RUN npm install -g --unsafe-perm \
      phantomjs-prebuilt \
      yarn

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install gems
ADD Gemfile* /app/
RUN bundle install

# Setup local
RUN sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_GB.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_GB.UTF-8

ENV LANG en_GB.UTF-8
