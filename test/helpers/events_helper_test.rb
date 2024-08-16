require "test_helper"

class EventsHelperTest < ActionView::TestCase
  def test_event_location_url
    event = create(:event)
    location = event_location(event)
    assert_match %r{^<a href="#{event.location_url}">#{event.location}</a>$}, location
  end

  def test_event_location_no_url
    event = create(:event, :location_url => nil)
    location = event_location(event)
    assert_match(/^#{event.location}$/, location)
  end
end
