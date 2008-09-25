class Friend < ActiveRecord::Base
  belongs_to :befriender, :class_name => "User", :foreign_key => :user_id
  belongs_to :befriendee, :class_name => "User", :foreign_key => :friend_user_id
end
