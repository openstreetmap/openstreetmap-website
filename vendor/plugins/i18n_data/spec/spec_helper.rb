# ---- requirements
require 'rubygems'
require 'activesupport'
require 'spec'
require 'mocha'

$LOAD_PATH << File.expand_path("../lib", File.dirname(__FILE__))
require 'i18n_data'

# ---- bugfix
#`exit?': undefined method `run?' for Test::Unit:Module (NoMethodError)
#can be solved with require test/unit but this will result in extra test-output
module Test
  module Unit
    def self.run?
      true
    end
  end
end


# ---- rspec
Spec::Runner.configure do |config|
  config.mock_with :mocha
end

# ---- Helpers
def pending_it(text,&block)
  it text do
    pending(&block)
  end
end