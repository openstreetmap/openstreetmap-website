module InlineSvgTemplateHandler
  def self.call(template, _source = nil)
    <<~RUBY
      InlineSvg.render(#{template.source.inspect}, local_assigns)
    RUBY
  end
end

ActionView::Template.register_template_handler :svg, InlineSvgTemplateHandler
