print "Using native MySQL\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db = 'file_column_test'

ActiveRecord::Base.establish_connection(
  :adapter  => "mysql",
  :host     => "localhost",
  :username => "rails",
  :password => "",
  :database => db,
  :socket => "/var/run/mysqld/mysqld.sock"
)

load File.dirname(__FILE__) + "/fixtures/schema.rb"
