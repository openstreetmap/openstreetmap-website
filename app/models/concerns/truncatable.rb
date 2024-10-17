module Truncatable
  extend ActiveSupport::Concern

  private

  def truncate_html(html, max_length, empty_tag_length = 500)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    accumulated_length = 0
    truncated_node = nil

    doc.traverse do |node|
      if accumulated_length >= max_length
        node.remove unless truncated_node.ancestors.include?(node)
        next
      end

      next unless node.children.empty?

      content_length = node.text? ? node.text.length : empty_tag_length
      if accumulated_length + content_length >= max_length
        node.content = node.text.truncate(max_length - accumulated_length) if node.text?
        truncated_node = node
      end

      accumulated_length += content_length
    end

    doc.to_html
  end
end
