print "Using IBM2 \n"
require 'logger'

gem 'ibm_db'
require 'IBM_DB'

RAILS_CONNECTION_ADAPTERS = %w( mysql postgresql sqlite firebird sqlserver db2 oracle sybase openbase frontbase ibm_db )


ActiveRecord::Base.logger = Logger.new("debug.log")

db1 = 'composite_primary_keys_unittest'

connection_options = {
  :adapter  => "ibm_db",
  :database => "ocdpdev",
  :username => "db2inst1",
  :password => "password",                      
  :host => '192.168.2.21'
}

ActiveRecord::Base.configurations = { db1 => connection_options }
ActiveRecord::Base.establish_connection(connection_options)
