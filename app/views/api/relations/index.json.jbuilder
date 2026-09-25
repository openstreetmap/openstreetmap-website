# frozen_string_literal: true

json.partial! "api/root_attributes"

json.elements do
  json.array! @relations, :partial => "relation", :as => :relation
end
