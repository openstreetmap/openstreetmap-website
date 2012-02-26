# Hack BufferedLogger to add timestamps to messages
module ActiveSupport
  class BufferedLogger
    alias_method :old_add, :add

    def add(severity, message = nil, progname = nil, &block)
      return if @level > severity
      message = (message || (block && block.call) || progname).to_s
      time = Time.now
      message = "[%s.%06d #%d] %s" % [time.strftime("%Y-%m-%d %H:%M:%S"), time.usec, $$, message.sub(/^\n+/, "")]
      old_add(severity, message)
    end
  end
end
