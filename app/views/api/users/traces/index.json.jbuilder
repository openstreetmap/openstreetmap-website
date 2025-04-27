# frozen_string_literal: true

json.partial! "api/root_attributes"

json.traces @traces do |trace|
  json.partial! "api/traces/trace", :trace => trace
end
