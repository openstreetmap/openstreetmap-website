json.partial! "api/root_attributes"

json.messages do
  json.array! @messages, :partial => "message", :as => :message
end
