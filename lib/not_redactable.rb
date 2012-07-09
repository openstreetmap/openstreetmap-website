require 'osm'

module NotRedactable
  def redacted?
    false
  end

  def redact!(r, m = nil)
    raise OSM::APICannotRedactError.new
  end
end
