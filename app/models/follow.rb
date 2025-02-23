# == Schema Information
#
# Table name: friends
#
#  id             :bigint           not null, primary key
#  user_id        :bigint           not null
#  friend_user_id :bigint           not null
#  created_at     :datetime
#
# Indexes
#
#  index_friends_on_user_id_and_created_at  (user_id,created_at)
#  user_id_idx                              (friend_user_id)
#
# Foreign Keys
#
#  friends_friend_user_id_fkey  (friend_user_id => users.id)
#  friends_user_id_fkey         (user_id => users.id)
#

class Follow < ApplicationRecord
  self.table_name = "friends"

  belongs_to :follower, :class_name => "User", :foreign_key => :user_id, :inverse_of => :follows
  belongs_to :following, :class_name => "User", :foreign_key => :friend_user_id, :inverse_of => :follows
end
