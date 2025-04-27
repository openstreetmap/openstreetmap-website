# frozen_string_literal: true

json.partial! "api/root_attributes"

json.elements do
  json.array! [@node], :partial => "node", :as => :node
end
