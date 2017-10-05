require "osm"

module NotRedactable
  def redacted?
    false
  end

  def redact!(_r)
    raise OSM::APICannotRedactError
  end
end
