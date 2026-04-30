# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.7
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Required on Windows
RUN mkdir -p /workspaces/openstreetmap-website \
    && chown -R vscode:vscode /workspaces/openstreetmap-website

# Install system packages then clean up to minimize image size
RUN apt-get update \
  && apt-get install --no-install-recommends -y \
    file \
    libarchive-dev \
    libgd-dev \
    osmosis \
  && apt-get clean \
  && apt-get distclean
