require 'osm'

module NotRedactable
  def redacted?
    false
  end

  def redact!(_r)
    fail OSM::APICannotRedactError.new
  end
end
