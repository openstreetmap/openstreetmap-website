require "test_helper"

class EventTest < ActiveSupport::TestCase
  def test_validations
    validate({}, true)

    validate({ :moment => nil }, false)
    validate({ :moment => "" }, false)
    validate({ :moment => "not a timestamp" }, false)
    validate({ :moment => "3030-30-30T30:30" }, false)

    validate({ :location => nil }, false)
    validate({ :location => "" }, false)

    validate({ :location => "a" * 255 }, true)
    validate({ :location => "a" * 256 }, false)

    validate({ :location_url => nil }, true)
    validate({ :location_url => "" }, true)

    validate({ :location_url => "foo" }, false)
    scheme = "https://"
    validate({ :location_url => scheme + ("a" * (255 - scheme.length)) }, true)
    validate({ :location_url => scheme + ("a" * (256 - scheme.length)) }, false)

    validate({ :latitude => 90 }, true)
    validate({ :latitude => 90.00001 }, false)
    validate({ :latitude => -90 }, true)
    validate({ :latitude => -90.00001 }, false)

    validate({ :longitude => 180 }, true)
    validate({ :longitude => 180.00001 }, false)
    validate({ :longitude => -180 }, true)
    validate({ :longitude => -180.00001 }, false)
  end

  def test_attendees
    # Zero
    event = create(:event)
    assert_equal(0, event.maybe_attendees.length)
    assert_equal(0, event.no_attendees.length)
    assert_equal(0, event.yes_attendees.length)

    # 1 Maybe
    ea = create(:event_attendance)
    assert_equal(1, ea.event.maybe_attendees.length)
    assert_equal(0, ea.event.no_attendees.length)
    assert_equal(0, ea.event.yes_attendees.length)
    assert_equal("Maybe", ea.event.event_attendances[0].intention)
    assert_equal(ea.user.display_name, ea.event.event_attendances[0].user.display_name)

    # 1 No
    ea = create(:event_attendance, :no)
    assert_equal(0, ea.event.maybe_attendees.length)
    assert_equal(1, ea.event.no_attendees.length)
    assert_equal(0, ea.event.yes_attendees.length)
    assert_equal("No", ea.event.event_attendances[0].intention)
    assert_equal(ea.user.display_name, ea.event.event_attendances[0].user.display_name)

    # 1 Yes
    ea = create(:event_attendance, :yes)
    assert_equal(0, ea.event.maybe_attendees.length)
    assert_equal(0, ea.event.no_attendees.length)
    assert_equal(1, ea.event.yes_attendees.length)
    assert_equal("Yes", ea.event.event_attendances[0].intention)
    assert_equal(ea.user.display_name, ea.event.event_attendances[0].user.display_name)

    # 2 Yes
    event = create(:event)
    u1 = create(:user)
    ea1 = EventAttendance.new(:event => event, :user => u1, :intention => EventAttendance::Intentions::YES)
    ea1.save
    u2 = create(:user)
    ea2 = EventAttendance.new(:event => event, :user => u2, :intention => EventAttendance::Intentions::YES)
    ea2.save
    assert_equal(2, event.yes_attendees.length)
    assert_equal(u1.display_name, event.yes_attendees[0].user.display_name)
    assert_equal(u2.display_name, event.yes_attendees[1].user.display_name)

    # 1 Yes and 1 No
    event = create(:event)
    u1 = create(:user)
    ea1 = EventAttendance.new(:event => event, :user => u1, :intention => EventAttendance::Intentions::NO)
    ea1.save
    u2 = create(:user)
    ea2 = EventAttendance.new(:event => event, :user => u2, :intention => EventAttendance::Intentions::YES)
    ea2.save
    assert_equal(1, event.yes_attendees.length)
    assert_equal(1, event.no_attendees.length)
    assert_equal(u2.display_name, event.yes_attendees[0].user.display_name)
  end
end
