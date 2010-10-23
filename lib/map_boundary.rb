module MapBoundary
  # Take an array of length 4, and return the min_lon, min_lat, max_lon and 
  # max_lat within their respective boundaries.
  def sanitise_boundaries(bbox)
    min_lon = [[bbox[0].to_f,-180].max,180].min
    min_lat = [[bbox[1].to_f,-90].max,90].min
    max_lon = [[bbox[2].to_f,+180].min,-180].max
    max_lat = [[bbox[3].to_f,+90].min,-90].max
    return min_lon, min_lat, max_lon, max_lat
  end

  def check_boundaries(min_lon, min_lat, max_lon, max_lat)
    # check the bbox is sane
    unless min_lon <= max_lon
      raise OSM::APIBadBoundingBox.new("The minimum longitude must be less than the maximum longitude, but it wasn't")
    end
    unless min_lat <= max_lat
      raise OSM::APIBadBoundingBox.new("The minimum latitude must be less than the maximum latitude, but it wasn't")
    end
    unless min_lon >= -180 && min_lat >= -90 && max_lon <= 180 && max_lat <= 90
      # Due to sanitize_boundaries, it is highly unlikely we'll actually get here
      raise OSM::APIBadBoundingBox.new("The latitudes must be between -90 and 90, and longitudes between -180 and 180")
    end

    # check the bbox isn't too large
    requested_area = (max_lat-min_lat)*(max_lon-min_lon)
    if requested_area > MAX_REQUEST_AREA
      raise OSM::APIBadBoundingBox.new("The maximum bbox size is " + MAX_REQUEST_AREA.to_s + 
        ", and your request was too large. Either request a smaller area, or use planet.osm")
    end
  end
end
