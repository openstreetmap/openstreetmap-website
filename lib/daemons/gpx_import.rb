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

        # TODO *nix specific, could do to work on windows... would be functionally inferior though - check for '.gz'
        gzipped = `file -b /tmp/#{trace.id}.gpx`.chomp =~/^gzip/

        if gzipped
          logger.info("gzipped")
        else
          logger.info("not gzipped")
        end
        gpx = OSM::GPXImporter.new("/tmp/#{trace.id}.gpx")

        f_lat = 0
        l_lon = 0
        first = true

        gpx.points do |point|
          if first
            f_lat = point['latitude']
            f_lon = point['longitude']
          end

          tp = Tracepoint.new
          tp.latitude = point['latitude']
          tp.longitude = point['longitude']
          tp.altitude = point['altitude']
          tp.user_id = trace.user.id
          tp.gpx_id = trace.id
          tp.trackid = point['segment']
          tp.save!
        end

        if gpx.actual_points > 0
          max_lat = Tracepoint.maximum('latitude', :conditions => ['gpx_id = ?', trace.id])
          min_lat = Tracepoint.minimum('latitude', :conditions => ['gpx_id = ?', trace.id])
          max_lon = Tracepoint.maximum('longitude', :conditions => ['gpx_id = ?', trace.id])
          min_lon = Tracepoint.minimum('longitude', :conditions => ['gpx_id = ?', trace.id])

          trace.latitude = f_lat
          trace.longitude = f_lon
          trace.large_picture = gpx.get_picture(min_lat, min_lon, max_lat, max_lon, gpx.actual_points)
          trace.icon_picture = gpx.get_icon(min_lat, min_lon, max_lat, max_lon)
          trace.size = gpx.actual_points
          trace.inserted = true
          trace.save
          Notifier::deliver_gpx_success(trace, gpx.possible_points)
        else
          #trace.destroy
          Notifier::deliver_gpx_failure(trace, '0 points parsed ok. Do they all have lat,lng,alt,timestamp?')
        end

      rescue Exception => ex
        #trace.destroy
        Notifier::deliver_gpx_failure(trace, ex.to_s + ex.backtrace.join("\n") )
      end
    end
  end
  sleep 15.minutes
end
