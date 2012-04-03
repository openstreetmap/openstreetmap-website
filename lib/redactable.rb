require 'osm'

module Redactable
  def self.included(base)
    # this is used to extend activerecord bases, as these aren't
    # in scope for the module itself.
    base.scope :unredacted, base.where(:redaction_id => nil)
  end
  
  def redacted?
    not self.redaction.nil?
  end

  def redact!(redaction)
    # check that this version isn't the current version
    raise OSM::APICannotRedactError.new if self.is_latest_version?

    # make the change
    self.redaction = redaction
    self.save!
  end
end
