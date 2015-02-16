# Setup any specified hard limit on the virtual size of the process
if defined?(HARD_MEMORY_LIMIT) && defined?(PhusionPassenger) && Process.const_defined?(:RLIMIT_AS)
  Process.setrlimit Process::RLIMIT_AS, HARD_MEMORY_LIMIT * 1024 * 1024, Process::RLIM_INFINITY
end

# If we're running under passenger and a soft memory limit is
# configured then setup some rack middleware to police the limit
if defined?(SOFT_MEMORY_LIMIT) && defined?(PhusionPassenger)
  # Define some rack middleware to police the soft memory limit
  class MemoryLimit
    def initialize(app)
      @app = app
    end

    def call(env)
      # Process this requst
      status, headers, body = @app.call(env)

      # Restart if we've hit our memory limit
      if resident_size > SOFT_MEMORY_LIMIT
        Process.kill("USR1", Process.pid)
      end

      # Return the result of this request
      [status, headers, body]
    end

    private

    def resident_size
      # Read statm to get process sizes. Format is
      #   Size RSS Shared Text Lib Data
      fields = File.open("/proc/self/statm") do |file|
        fields = file.gets.split(" ")
      end

      # Return resident size in megabytes
      fields[1].to_i / 256
    end
  end

  # Install the memory limit checker
  Rails.configuration.middleware.use MemoryLimit
end
