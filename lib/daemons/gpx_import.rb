#!/usr/bin/env ruby

#You might want to change this
#ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

terminated = false

logger = ActiveRecord::Base.logger

while(true) do
  ActiveRecord::Base.logger.info("GPX Import daemon wake @ #{Time.now}.")

  Trace.find(:all, :conditions => 'inserted = 0 and visible = 1').each do |trace|
    Signal.trap("TERM") do 
      terminated = true
    end

    begin
      gpx = trace.import

      if gpx.actual_points > 0
        Notifier::deliver_gpx_success(trace, gpx.actual_points)
      else
        trace.destroy
        Notifier::deliver_gpx_failure(trace, '0 points parsed ok. Do they all have lat,lng,alt,timestamp?')
      end
    rescue Exception => ex
      logger.info ex.to_s
      ex.backtrace.each {|l| logger.info l }
      trace.destroy
      Notifier::deliver_gpx_failure(trace, ex.to_s + "\n" + ex.backtrace.join("\n"))
    end

    Signal.trap("TERM", "DEFAULT")

    exit if terminated
  end

  Trace.find(:all, :conditions => 'visible = 0').each do |trace|
    Signal.trap("TERM") do 
      terminated = true
    end

    begin
      trace.destroy
    rescue Exception => ex
      logger.info ex.to_s
      ex.backtrace.each {|l| logger.info l }
    end

    Signal.trap("TERM", "DEFAULT")

    exit if terminated
  end

  sleep 5.minutes
end
