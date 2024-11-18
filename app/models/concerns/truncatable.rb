module Truncatable
  extend ActiveSupport::Concern

  private

  def truncate_html(html, max_length, empty_tag_length = 1000)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    accumulated_length = 0
    last_child = nil

    doc.traverse do |node|
      if accumulated_length >= max_length
        node.remove unless !last_child.nil? && last_child.ancestors.include?(node)
        next
      end

      next unless node.children.empty?

      accumulated_length += node.text? ? node.text.length : empty_tag_length
      if accumulated_length < max_length
        last_child = node
      else
        node.remove
      end
    end

    RichText::SimpleFormat.new.sanitize(doc)
  end
end
