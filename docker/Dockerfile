FROM ruby:2.5-slim

#install packages
#fixes dpkg man page softlink error while installing postgresql-client [source: https://github.com/debuerreotype/debuerreotype/issues/10#issuecomment-438342078]
RUN mkdir -p /usr/share/man/man1 && mkdir -p /usr/share/man/man7
RUN apt-get update && apt-get install curl -y
RUN curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh && bash nodesource_setup.sh && rm nodesource_setup.sh
RUN apt-get install -y --no-install-recommends ruby-dev libarchive-dev libmagickwand-dev libxml2-dev libxslt1-dev build-essential libpq-dev libsasl2-dev imagemagick libffi-dev locales postgresql-client-9.6 nodejs && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN npm install yarn -g

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install gems
ADD Gemfile* /app/
RUN bundle install --jobs=2

# Setup local
RUN sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_GB.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_GB.UTF-8

ENV LANG en_GB.UTF-8
