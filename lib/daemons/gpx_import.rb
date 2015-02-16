#!/usr/bin/env ruby

# You might want to change this
# ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

terminated = false

logger = ActiveRecord::Base.logger

loop do
  ActiveRecord::Base.logger.info("GPX Import daemon wake @ #{Time.now}.")

  Trace.find(:all, :conditions => { :inserted => false, :visible => true }, :order => "id").each do |trace|
    Signal.trap("TERM") do
      terminated = true
    end

    begin
      gpx = trace.import

      if gpx.actual_points > 0
        Notifier.gpx_success(trace, gpx.actual_points).deliver
      else
        Notifier.gpx_failure(trace, '0 points parsed ok. Do they all have lat,lng,alt,timestamp?').deliver
        trace.destroy
      end
    rescue Exception => ex
      logger.info ex.to_s
      ex.backtrace.each { |l| logger.info l }
      Notifier.gpx_failure(trace, ex.to_s + "\n" + ex.backtrace.join("\n")).deliver
      trace.destroy
    end

    Signal.trap("TERM", "DEFAULT")

    exit if terminated
  end

  Trace.find(:all, :conditions => { :visible => false }, :order => "id").each do |trace|
    Signal.trap("TERM") do
      terminated = true
    end

    begin
      trace.destroy
    rescue Exception => ex
      logger.info ex.to_s
      ex.backtrace.each { |l| logger.info l }
    end

    Signal.trap("TERM", "DEFAULT")

    exit if terminated
  end

  sleep 5.minutes.value
end
