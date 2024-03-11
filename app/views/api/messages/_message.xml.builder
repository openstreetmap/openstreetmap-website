xml.tag! "message", :id => message.id,
                    :from_user_id => message.from_user_id,
                    :to_user_id => message.to_user_id,
                    :sent_on => message.sent_on.xmlschema,
                    :message_read => message.message_read,
                    :from_user_visible => message.from_user_visible,
                    :to_user_visible => message.to_user_visible,
                    :body_format => message.body_format do
  xml.tag! "title", message.title
  xml.tag! "body", message.body unless @skip_body
end
