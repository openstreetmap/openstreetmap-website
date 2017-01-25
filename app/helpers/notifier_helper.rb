module NotifierHelper
  def fp(text)
    format_paragraph(text, 72, 0)
  end

  def link_to_user(display_name)
    link_to(
      display_name,
      user_url(display_name, :host => SERVER_URL),
      :target => "_blank",
      :style => "text-decoration: none; color: #222; font-weight: bold"
    )
  end

  def message_body(&block)
    render(
      :partial => "message_body",
      :locals => { :body => capture(&block) }
    )
  end

  def apply_inline_css(html)
    html.gsub /<p>/, '<p style="color: black; margin: 0.75em 0">'
  end
end
