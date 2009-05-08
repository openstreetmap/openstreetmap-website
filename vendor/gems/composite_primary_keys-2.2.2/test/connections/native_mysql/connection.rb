print "Using native MySQL\n"
require 'fileutils'
require 'logger'
require 'adapter_helper/mysql'

log_path = File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. .. log]))
FileUtils.mkdir_p log_path
puts "Logging to #{log_path}/debug.log"
ActiveRecord::Base.logger = Logger.new("#{log_path}/debug.log")

# Adapter config setup in locals/database_connections.rb
connection_options = AdapterHelper::MySQL.load_connection_from_env
ActiveRecord::Base.establish_connection(connection_options)
