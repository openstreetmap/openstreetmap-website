require "test/unit"

module ActionController
  class Base
    def self.after_filter(*args)
      
    end
  end
end

$LOAD_PATH.push(File.dirname(__FILE__) + "../lib")
require "../init"

class SessionPersistenceTest < Test::Unit::TestCase
  def setup
    @controller = ActionController::Base.new
    @controller.instance_eval {
      def session
        @session ||= {}
      end
      
      def session_persistence_key
        :mine
      end
    }
  end
  
  def test_session_expires_after
    @controller.instance_eval { session_expires_after 10 }
    assert_equal 10, @controller.session[:mine]
  end
  
  def test_session_expires_automatically
    @controller.instance_eval {
      session_expires_after 10
      session_expires_automatically
    }
    
    assert !@controller.session.has_key?(:mine)
  end
end