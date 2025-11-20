# frozen_string_literal: true

module SpamScorer
  SPAMMY_PHRASES = [
    "Business Description:", "Additional Keywords:"
  ].freeze

  def self.new_from_rich_text(text)
    self::RichText.new(text)
  end

  def self.new_from_user(user)
    self::User.new(user)
  end
end
