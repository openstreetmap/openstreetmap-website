require "test_helper"

class EventHelperTest < ActionView::TestCase
  def test_event_location_url
    event = create(:event)
    location = event_location(event)
    assert_match "<a href=\"http://example.com/app/1\">Location 1</a>", location
  end

  def test_event_location_no_url
    event = create(:event, :location_url => nil)
    location = event_location(event)
    assert_match "Location 1", location
  end
end
