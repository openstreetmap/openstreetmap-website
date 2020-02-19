require "test_helper"

class EventTest < ActiveSupport::TestCase
  def test_validations
    validate({}, true)

    validate({ :moment => nil }, false)
    validate({ :moment => "" }, false)
    validate({ :moment => "not a timestamp" }, false)
    validate({ :moment => "3030-30-30T30:30" }, false)

    validate({ :location => nil }, true)
    validate({ :location => "" }, false)

    validate({ :location => "a" * 255 }, true)
    validate({ :location => "a" * 256 }, false)

    validate({ :location_url => nil }, true)
    validate({ :location_url => "" }, false)

    validate({ :location_url => "foo" }, false)
    scheme = "https://"
    validate({ :location_url => scheme + "a" * (255 - scheme.length) }, true)
    validate({ :location_url => scheme + "a" * (256 - scheme.length) }, false)

    validate({ :latitude => 90 }, true)
    validate({ :latitude => 90.00001 }, false)
    validate({ :latitude => -90 }, true)
    validate({ :latitude => -90.00001 }, false)

    validate({ :longitude => 180 }, true)
    validate({ :longitude => 180.00001 }, false)
    validate({ :longitude => -180 }, true)
    validate({ :longitude => -180.00001 }, false)
  end

  # There's a possibility to factory this out.  See microcosm_member_test.rb.
  def validate(attrs, result = true)
    object = build(:event, attrs)
    valid = object.valid?
    errors = object.errors.messages
    assert_equal result, valid, "Expected #{attrs.inspect} to be #{result} but #{errors}"
  end
end
