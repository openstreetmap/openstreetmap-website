require 'osm'

module Redactable
  def redacted?
    not self.redaction.nil?
  end

  def redact!(redaction)
    # check that this version isn't the current version
    raise OSM::APICannotRedactError.new if self.is_latest_version?

    # make the change
    self.redaction = redaction
  end
end
