json.partial! "api/root_attributes"

json.set! :preferences do
  json.set! @preference.k, @preference.v
end
