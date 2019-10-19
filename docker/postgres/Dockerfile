FROM postgres:9.5

RUN apt-get update && \
    apt-get install -y \
      build-essential \
      curl \
      libcurl4-openssl-dev \
      libreadline-dev \
      libssl-dev \
      libxml2-dev \
      postgresql-server-dev-all \
      zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# compiling ruby from source as official debian has ruby 2.3 and we need => 2.4
RUN curl -L https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.4.tar.gz | tar zx && \
    cd ruby-2.6.4 && \
    ./configure && \
    make && \
    make install && \
    cd ..  && \
    rm -rf ruby-2.6.4

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install gems
ADD Gemfile* /app/
RUN bundle install

# add database functions and init scripts
ADD db/functions/ /app/db/functions/
ADD docker/postgres/docker_postgres.sh docker-entrypoint-initdb.d/docker_postgres.sh

# change ownership to postgres as while running docker_postgres.sh postgres will need write access
RUN chown -R postgres /app/db
