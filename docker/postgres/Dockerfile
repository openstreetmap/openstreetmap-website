FROM postgres:11

ADD docker/docker_postgres.sh docker-entrypoint-initdb.d/docker_postgres.sh

# compiling ruby from source as official debian has ruby 2.3 and we need => 2.4
RUN apt-get update
RUN apt-get install -y curl build-essential libreadline-dev libssl-dev libcurl4-openssl-dev postgresql-server-dev-all zlib1g-dev libxml2-dev
RUN curl -L https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.4.tar.gz | tar zx
RUN cd ruby-2.6.4 && ./configure && make && make install
RUN cd ..  && rm -r ruby-2.6.4
RUN apt-get clean && rm -rf /var/lib/apt/lists/*


# Setup app location
RUN mkdir -p /app
WORKDIR /app

# add database functions directory
ADD db/functions/ /app/db/functions/

# Install gems
ADD Gemfile* /app/
RUN bundle install

# change ownership to postgres as while running docker_postgres.sh postgres will need write access
RUN chown -R postgres /app/db
