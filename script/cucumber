#!/usr/bin/env ruby
# frozen_string_literal: true

vendored_cucumber_bin = Dir["#{File.dirname(__FILE__)}/../vendor/{gems,plugins}/cucumber*/bin/cucumber"].first
if vendored_cucumber_bin
  load File.expand_path(vendored_cucumber_bin)
else
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  require 'cucumber'
  load Cucumber::BINARY
end
