#!/usr/bin/env ruby

#You might want to change this
#ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

terminated = false

logger = ActiveRecord::Base.logger

while(true) do
  ActiveRecord::Base.logger.info("GPX Import daemon wake @ #{Time.now}.")

  Trace.find(:all, :conditions => ['inserted = ?', false]).each do |trace|
    Signal.trap("TERM") do 
      terminated = true
    end

    trace.import

    Signal.trap("TERM", "DEFAULT")

    exit if terminated
  end

  sleep 15.minutes
end
