class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => "User", :foreign_key => :from_user_id
  belongs_to :recipient, :class_name => "User", :foreign_key => :to_user_id
end
