# frozen_string_literal: true

json.partial! "api/root_attributes"

json.elements do
  json.array! @ways, :partial => "way", :as => :way
end
