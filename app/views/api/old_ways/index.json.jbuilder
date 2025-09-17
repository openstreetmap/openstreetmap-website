# frozen_string_literal: true

json.partial! "api/root_attributes"

json.elements do
  json.array! @elements, :partial => "old_way", :as => :old_way
end
