json.partial! "api/root_attributes"

json.user_blocks do
  json.array! @user_blocks, :partial => "api/user_blocks/user_block", :as => :user_block
end
