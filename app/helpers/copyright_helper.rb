# frozen_string_literal: true

module CopyrightHelper
  def legal_babble_paragraph(name, links: [], local_links: {}, **)
    link_options = {}
    links.each do |link_name|
      link_options[:"#{link_name}_link"] = link_to(t(".legal_babble.#{name}_#{link_name}"),
                                                   t(".legal_babble.#{name}_#{link_name}_url"))
    end
    local_links.each do |link_name, link_path|
      link_options[:"#{link_name}_link"] = link_to(t(".legal_babble.#{name}_#{link_name}"), link_path)
    end
    t ".legal_babble.#{name}_html", **link_options, **
  end
end
