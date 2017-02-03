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

  def style_message(html)
    # Because we can't use stylesheets in HTML emails, we need to inline the
    # styles. Rather than copy-paste the same string of CSS into every message,
    # we apply it once here, after the message has been composed.
    html.gsub /<p>/, '<p style="color: black; margin: 0.75em 0; font-family: \'Helvetica Neue\', Arial, Sans-Serif">'
  end
end
