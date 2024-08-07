json.partial! "api/root_attributes"

json.users do
  json.array! @users, :partial => "user", :as => :user
end
