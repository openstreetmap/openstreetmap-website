attrs = {
  "id" => message.id,
  "from_user_id" => message.from_user_id,
  "to_user_id" => message.to_user_id,
  "sent_on" => message.sent_on.xmlschema,
  "body_format" => message.body_format
}

if current_user.id == message.from_user_id
  attrs["from_user_visible"] = message.from_user_visible
elsif current_user.id == message.to_user_id
  attrs["message_read"] = message.message_read
  attrs["to_user_visible"] = message.to_user_visible
end

xml.message(attrs) do |nd|
  nd.title(message.title)
  nd.body(message.body) unless @skip_body
end
