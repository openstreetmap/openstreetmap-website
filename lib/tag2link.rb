# frozen_string_literal: true

module Tag2link
  def self.link(key, value)
    # skip if it's a full URL
    return nil if %r{\Ahttps?://}.match?(value)

    url_template = TAG2LINK[key]
    return nil unless url_template

    url_template.gsub("$1", value)
  end
end
