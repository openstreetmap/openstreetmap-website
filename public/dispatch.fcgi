#!/usr/bin/ruby1.8
#
# You may specify the path to the FastCGI crash log (a log of unhandled
# exceptions which forced the FastCGI instance to exit, great for debugging)
# and the number of requests to process before running garbage collection.
#
# By default, the FastCGI crash log is RAILS_ROOT/log/fastcgi.crash.log
# and the GC period is nil (turned off).  A reasonable number of requests
# could range from 10-100 depending on the memory footprint of your app.
#
# Example:
#   # Default log path, normal GC behavior.
#   RailsFCGIHandler.process!
#
#   # Default log path, 50 requests between GC.
#   RailsFCGIHandler.process! nil, 50
#
#   # Custom log path, normal GC behavior.
#   RailsFCGIHandler.process! '/var/log/myapp_fcgi_crash.log'
#
require File.dirname(__FILE__) + "/../config/environment"
require 'fcgi_handler'

class OpenStreetMapFCGIHandler < RailsFCGIHandler
protected
  def process_request(cgi)
    # Call superclass to process the request
    super

    # Restart if we've hit our memory limit
    if resident_size > 512
      run_gc!

      if resident_size > 512
        dispatcher_log :info, "restarting due to memory limit"
        restart!
      end
    end
  end

  def resident_size
    # Read statm to get process sizes. Format is
    #   Size RSS Shared Text Lib Data
    fields = File.open("/proc/self/statm") do |file|
      fields = file.gets.split(" ")
    end

    # Return resident size in megabytes
    return fields[1].to_i / 256
  end

end

OpenStreetMapFCGIHandler.process! nil, 10
