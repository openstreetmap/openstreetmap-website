module EventsHelper
  def event_location(event)
    if event.location_url.present?
      link_to event.location, event.location_url
    else
      event.location
    end
  end
end
