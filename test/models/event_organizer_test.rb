require "test_helper"

class EventOrganizerTest < ActiveSupport::TestCase
  def test_eventorganizer_validations
    validate({})
  end

  # There's a possibility to factory this out.  See microcosm_test.rb.
  def validate(attrs, result = true)
    object = build(:event_organizer, attrs)
    valid = object.valid?
    errors = object.errors.messages
    assert_equal result, valid, "Expected #{attrs.inspect} to be #{result} but #{errors}"
  end
end
