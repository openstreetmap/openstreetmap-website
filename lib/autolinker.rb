# frozen_string_literal: true

class Autolinker
  def self.auto_link(html, mode = :urls, link_attr = nil, &)
    link_attr ||= {
      :rel => "nofollow noopener noreferrer",
      :dir => "auto"
    }
    options = {
      :html => link_attr,
      :link => mode,
      :sanitize => false
    }
    ActionController::Base.helpers.auto_link(html, options, &)
  end
end
