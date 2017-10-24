# == Schema Information
#
# Table name: friends
#
#  id             :integer          not null, primary key
#  user_id        :integer          not null
#  friend_user_id :integer          not null
#
# Indexes
#
#  friends_user_id_idx  (user_id)
#  user_id_idx          (friend_user_id)
#
# Foreign Keys
#
#  friends_friend_user_id_fkey  (friend_user_id => users.id)
#  friends_user_id_fkey         (user_id => users.id)
#

class Friend < ActiveRecord::Base
  belongs_to :befriender, :class_name => "User", :foreign_key => :user_id
  belongs_to :befriendee, :class_name => "User", :foreign_key => :friend_user_id
end
