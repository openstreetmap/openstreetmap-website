print "Using native Postgresql\n"
require 'logger'
require 'adapter_helper/postgresql'

ActiveRecord::Base.logger = Logger.new("debug.log")

# Adapter config setup in locals/database_connections.rb
connection_options = AdapterHelper::Postgresql.load_connection_from_env
ActiveRecord::Base.establish_connection(connection_options)
