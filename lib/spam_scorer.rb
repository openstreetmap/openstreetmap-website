# frozen_string_literal: true

module SpamScorer
  SPAMMY_PHRASES = [
    "Business Description:", "Additional Keywords:"
  ].freeze

  def self.new_from_rich_text(text)
    self::RichText.new(text)
  end
end
