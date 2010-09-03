$:.unshift(File.dirname(__FILE__) + '/../lib')
RAILS_ROOT = File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'
require "#{File.dirname(__FILE__)}/../init"


config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'plugin_test'])

load(File.dirname(__FILE__) + "/schema.rb") if File.exist?(File.dirname(__FILE__) + "/schema.rb")

if ActiveSupport.const_defined?(:TestCase)
  ActiveSupport::TestCase.send(:include, ActiveRecord::TestFixtures)
  TEST_CASE = ActiveSupport::TestCase
else
  TEST_CASE = Test::Unit::TestCase
end

TEST_CASE.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(TEST_CASE.fixture_path)

class TEST_CASE #:nodoc:
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(TEST_CASE.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(TEST_CASE.fixture_path, table_names)
    end
  end

  self.use_transactional_fixtures = false
  
  self.use_instantiated_fixtures  = false
end

