require 'osm'

module NotRedactable
  def redacted?
    false
  end

  def redact!(r)
    raise OSM::APICannotRedactError.new
  end
end
