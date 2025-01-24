json.id message.id
json.from_user_id message.from_user_id
json.from_display_name message.sender.display_name
json.to_user_id message.to_user_id
json.to_display_name message.recipient.display_name
json.title message.title
json.sent_on message.sent_on.xmlschema

json.message_read message.message_read if current_user.id == message.to_user_id

if current_user.id == message.from_user_id
  json.deleted !message.from_user_visible
elsif current_user.id == message.to_user_id
  json.deleted !message.to_user_visible
end

json.body_format message.body_format
json.body message.body unless @skip_body
