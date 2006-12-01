#!/usr/bin/env ruby

#You might want to change this
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

$running = true;
Signal.trap("TERM") do 
  $running = false
end

while($running) do
  
  ActiveRecord::Base.logger.info("GPX Import daemon wake @ #{Time.now}.")

  traces = Trace.find(:all, :conditions => ['inserted = ?', false])

  if traces and traces.length > 0
    traces.each do |trace|
      begin

        ActiveRecord::Base.logger.info("GPX Import importing #{trace.name} from #{trace.user.email}")

        #  gpx = OSM::GPXImporter.new('/tmp/2.gpx')
        #  gpx.points do |point|
        #    puts point['latitude']
        #  end
        
        Notifier::deliver_gpx_success(trace)
      rescue
        Notifier::deliver_gpx_failure(trace)
      end
    end
  end
  sleep 15.minutes
end
