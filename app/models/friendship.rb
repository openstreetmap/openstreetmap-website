# == Schema Information
#
# Table name: friends
#
#  id             :bigint(8)        not null, primary key
#  user_id        :bigint(8)        not null
#  friend_user_id :bigint(8)        not null
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

class Friendship < ApplicationRecord
  self.table_name = "friends"

  belongs_to :befriender, :class_name => "User", :foreign_key => :user_id
  belongs_to :befriendee, :class_name => "User", :foreign_key => :friend_user_id
end
