# frozen_string_literal: true

module NotRedactable
  extend ActiveSupport::Concern

  def redacted?
    false
  end

  def redact!(_r)
    raise OSM::APICannotRedactError
  end
end
