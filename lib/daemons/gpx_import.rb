#!/usr/bin/env ruby

#You might want to change this
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

$running = true;
Signal.trap("TERM") do 
  $running = false
end

logger = ActiveRecord::Base.logger

while($running) do
  
  ActiveRecord::Base.logger.info("GPX Import daemon wake @ #{Time.now}.")

  traces = Trace.find(:all, :conditions => ['inserted = ?', false])

  if traces and traces.length > 0
    traces.each do |trace|
      begin

        logger.info("GPX Import importing #{trace.name} from #{trace.user.email}")

        gzipped = `file -b /tmp/#{trace.id}.gpx`.chomp =~/^gzip/

        if gzipped
          logger.info("gzipped")
        else
          logger.info("not gzipped")
        end
        gpx = OSM::GPXImporter.new("/tmp/#{trace.id}.gpx")

        gpx.points do |point|
          tp = Tracepoint.new
          tp.latitude = point['latitude']
          tp.latitude = point['longitude']
          tp.altitude = point['altitude']
          tp.user_id = trace.user.id
          tp.gpx_id = trace.id
          tp.trackid = point['segment']
        end 
        trace.size = gpx.actual_points
        trace.inserted = true
        trace.save
        Notifier::deliver_gpx_success(trace, gpx.possible_points)
      rescue Exception => ex
        trace.destroy
        Notifier::deliver_gpx_failure(trace, ex.to_s)
      end
    end
  end
  sleep 15.minutes
end
