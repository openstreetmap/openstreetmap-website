# frozen_string_literal: true

module Linkify
  LINK_ATTRIBUTES = 'rel="nofollow noopener noreferrer" dir="auto"'

  def self.call(text)
    text = ERB::Util.h(text) unless text.html_safe?

    Rinku.auto_link(text, :urls, LINK_ATTRIBUTES).html_safe
  end
end
