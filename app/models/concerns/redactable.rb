module Redactable
  extend ActiveSupport::Concern

  included do
    scope :unredacted, -> { where(:redaction_id => nil) }
  end

  def redacted?
    !redaction.nil?
  end

  def redact!(redaction)
    # check that this version isn't the current version
    raise OSM::APICannotRedactError if latest_version?

    # make the change
    self.redaction = redaction
    save!
  end
end
