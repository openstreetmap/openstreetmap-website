module UserMailerHelper
  def fp(text)
    format_paragraph(text, 72, 0)
  end

  def em(text)
    "_#{text}_"
  end

  def strong(text)
    "*#{text}*"
  end

  def link_to_user(display_name)
    link_to(
      tag.strong(
        display_name,
        # NB we need "text-decoration: none" twice: GMail only honours it on
        # the <a> but Outlook only on the <strong>
        :style => "text-decoration: none"
      ),
      user_url(display_name, :host => Settings.server_url),
      :target => "_blank",
      :rel => "noopener",
      :style => "text-decoration: none; color: #222"
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
    html.gsub("<p>", '<p style="color: black; margin: 0.75em 0; font-family: \'Helvetica Neue\', Arial, Sans-Serif">')
  end

  def style_left
    I18n.t("html.dir") == "ltr" ? "left" : "right"
  end

  def style_right
    I18n.t("html.dir") == "ltr" ? "right" : "left"
  end
end
