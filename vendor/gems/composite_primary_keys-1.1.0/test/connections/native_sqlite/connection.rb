print "Using native Sqlite3\n"
require 'logger'
require 'adapter_helper/sqlite3'

ActiveRecord::Base.logger = Logger.new("debug.log")

# Adapter config setup in locals/database_connections.rb
connection_options = AdapterHelper::Sqlite3.load_connection_from_env
ActiveRecord::Base.establish_connection(connection_options)
