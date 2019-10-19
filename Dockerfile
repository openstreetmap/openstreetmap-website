FROM ruby:2.5-slim

# install packages
# fixes dpkg man page softlink error while installing postgresql-client [source: https://stackoverflow.com/a/52655008/5350059]
RUN mkdir -p /usr/share/man/man1 && mkdir -p /usr/share/man/man7
RUN apt-get update && apt-get install curl -y
RUN apt-get clean && rm -rf /var/lib/apt/lists/*


#npm is not available in Debian repo so following official instruction [source: https://github.com/nodesource/distributions/blob/master/README.md#debinstall]
RUN curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh && bash nodesource_setup.sh && rm nodesource_setup.sh
RUN apt-get install -y --no-install-recommends ruby-dev libarchive-dev libmagickwand-dev libxml2-dev libxslt1-dev build-essential libpq-dev libsasl2-dev imagemagick libffi-dev locales postgresql-client nodejs osmosis
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN npm install yarn phantomjs-prebuilt -g --unsafe-perm


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
