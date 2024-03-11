json.id message.id
json.from_user_id message.from_user_id
json.to_user_id message.to_user_id
json.title message.title
json.sent_on message.sent_on.xmlschema

if current_user.id == message.from_user_id
  json.from_user_visible message.from_user_visible
elsif current_user.id == message.to_user_id
  json.message_read message.message_read
  json.to_user_visible message.to_user_visible
end

json.body_format message.body_format
json.body message.body unless @skip_body
