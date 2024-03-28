json.partial! "api/root_attributes"

json.messages(@messages) do |message|
  xml.tag! "messages" do
    json.partial! message
  end
end
