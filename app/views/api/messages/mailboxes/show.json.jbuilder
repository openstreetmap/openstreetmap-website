json.partial! "api/root_attributes"

json.messages do
  json.array! @messages, :partial => "api/messages/message", :as => :message
end
