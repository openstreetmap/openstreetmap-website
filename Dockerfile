FROM ruby:2.3

ARG OSM_overpass_url=//overpass-api.de/api/interpreter
ARG OSM_nominatim_url=//nominatim.openstreetmap.org/

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO- https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      apache2 \
      apache2-dev \
      build-essential \
      git \
      git-core \
      imagemagick \
      jhead \
      libmagickwand-dev \
      libpq-dev  \
      libpq-dev \
      libsasl2-dev \
      libxml2-dev \ 
      libxslt1-dev \
      nodejs \
      npm \
      vim \
      yarn \
    && rm -rf /var/lib/apt/lists/*

# ###########################
# CODE SNIPPET FROM osm-seed
# https://github.com/developmentseed/osm-seed/blob/23708f12cdd3c4b804f27571f0eaede045cb0868/openstreetmap-website/Dockerfile#L26-L43
# Fixing image_optim issues, installing a bush of libraries from : https://github.com/toy/image_optim#pngout-installation-optional
# RUN apt-get install -y advancecomp gifsicle jhead jpegoptim optipng
RUN git clone --recursive https://github.com/kornelski/pngquant.git && \
    cd pngquant && \
    ./configure && \
    make && \
    make install
RUN git clone https://github.com/tjko/jpeginfo.git && \
    cd jpeginfo && \
    ./configure && \
    make && \
    make strip && \
    make install
RUN wget http://iweb.dl.sourceforge.net/project/pmt/pngcrush/1.8.12/pngcrush-1.8.12.tar.gz && \
    tar zxf pngcrush-1.8.12.tar.gz && \
    cd pngcrush-1.8.12 && \
    make && cp -f pngcrush /usr/local/bin
# ###########################

# Install the latest version of nodejs
RUN npm install npm -g && \
  npm cache clean -f && \
  npm install -g n \
  n stable

# Install the image tools needed for image_optim
RUN mkdir -p /usr/lib/node_modules/advpng-bin/
RUN npm install -g \
      advpng-bin \
      gifsicle \
      imagemin-svgo \
      img-optim \
      jpegoptim-bin \
      optipng-bin \
      pngcrush-bin \
      pngquant-bin \
      svgo \
    --unsafe-perm=true \
    --allow-root

RUN mkdir -p /ohm-website
WORKDIR /ohm-website

# bundle install takes a while, so only copy these in if Gemfiles have changed
ADD ./Gemfile /ohm-website/Gemfile
ADD ./Gemfile.lock /ohm-website/Gemfile.lock
RUN echo 'gem "passenger", ">= 5.0.25", require: "phusion_passenger/rack_handler"' >> /ohm-website/Gemfile
RUN bundle install -j $(nproc)

# copy the Rails app in
COPY . /ohm-website/
# update the Gemfile again so that rails server knows to use Passenger
RUN echo 'gem "passenger", ">= 5.0.25", require: "phusion_passenger/rack_handler"' >> /ohm-website/Gemfile

# update vendored iD
RUN rm -rf vendor/assets/iD
RUN vendorer 

# initialize configurations (to be overridden using environment variables)
RUN cp config/example.application.yml config/application.yml
RUN cp config/example.database.yml config/database.yml

# generate translated JS
RUN bundle exec rake i18n:js:export
# precompile the asset pipeline
RUN bundle exec rake assets:precompile

# 1. update the database with the current environment (known at runtime)
# 2. start the app
ENTRYPOINT \
  bundle exec rails db:environment:set RAILS_ENV=$RAILS_ENV && \
  bundle exec rails server -p $OSM_server_port -b 0.0.0.0