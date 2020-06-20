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

  def test_location
    event = build(:event)
    assert event.location?
    event.location = nil
    assert_not event.location?
  end

  def test_location_url
    event = build(:event)
    assert event.location_url?
    event.location_url = nil
    assert_not event.location_url?
  end

  def test_attendees
    # Zero
    event = create(:event)
    assert_equal(0, event.attendees.length)

    # 1 Yes
    ea = create(:event_attendance)
    assert_equal(1, ea.event.attendees.length)
    assert_equal(ea.user.display_name, ea.event.attendees[0].user.display_name)

    # 1 No
    ea = create(:event_attendance, :no)
    assert_equal(0, ea.event.attendees.length)

    # 2 Yes
    event = create(:event)
    u1 = create(:user)
    ea1 = EventAttendance.new(:event => event, :user => u1, :intention => "Yes")
    ea1.save
    u2 = create(:user)
    ea2 = EventAttendance.new(:event => event, :user => u2, :intention => "Yes")
    ea2.save
    assert_equal(2, event.attendees.length)
    assert_equal(u1.display_name, event.attendees[0].user.display_name)
    assert_equal(u2.display_name, event.attendees[1].user.display_name)

    # 1 Yes and 1 No
    event = create(:event)
    u1 = create(:user)
    ea1 = EventAttendance.new(:event => event, :user => u1, :intention => "No")
    ea1.save
    u2 = create(:user)
    ea2 = EventAttendance.new(:event => event, :user => u2, :intention => "Yes")
    ea2.save
    assert_equal(1, event.attendees.length)
    assert_equal(u2.display_name, event.attendees[0].user.display_name)
  end
end
