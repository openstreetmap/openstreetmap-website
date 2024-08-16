require "test_helper"

class EventOrganizerTest < ActiveSupport::TestCase
  def test_eventorganizer_validations
    validate({}, true)
  end
end
