# == Schema Information
#
# Table name: user_preferences
#
#  user_id :bigint(8)        not null, primary key
#  k       :string           not null, primary key
#  v       :string           not null
#
# Foreign Keys
#
#  user_preferences_user_id_fkey  (user_id => users.id)
#

class UserPreference < ActiveRecord::Base
  self.primary_keys = "user_id", "k"

  belongs_to :user

  validates :user, :presence => true, :associated => true
  validates :k, :v, :length => 1..255, :characters => true
end
