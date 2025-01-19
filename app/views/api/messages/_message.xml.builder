attrs = {
  "id" => message.id,
  "from_user_id" => message.from_user_id,
  "from_display_name" => message.sender.display_name,
  "to_user_id" => message.to_user_id,
  "to_display_name" => message.recipient.display_name,
  "sent_on" => message.sent_on.xmlschema,
  "body_format" => message.body_format
}

attrs["message_read"] = message.message_read if current_user.id == message.to_user_id

if current_user.id == message.from_user_id
  attrs["deleted"] = !message.from_user_visible
elsif current_user.id == message.to_user_id
  attrs["deleted"] = !message.to_user_visible
end

xml.message(attrs) do |nd|
  nd.title(message.title)
  nd.body(message.body) unless @skip_body
end
