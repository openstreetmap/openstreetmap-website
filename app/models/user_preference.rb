# == Schema Information
#
# Table name: user_preferences
#
#  user_id :integer          not null, primary key
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
  validates :k, :v, :length => 1..255, :invalid_chars => true

  # Turn this Node in to an XML Node without the <osm> wrapper.
  def to_xml_node
    el1 = XML::Node.new "preference"
    el1["k"] = k
    el1["v"] = v

    el1
  end
end
