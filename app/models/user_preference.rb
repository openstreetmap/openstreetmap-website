class UserPreference < ActiveRecord::Base
  self.primary_keys = "user_id", "k"

  belongs_to :user

  validates_length_of :k, :within => 1..255
  validates_length_of :v, :within => 1..255

  # Turn this Node in to an XML Node without the <osm> wrapper.
  def to_xml_node
    el1 = XML::Node.new 'preference'
    el1['k'] = k
    el1['v'] = v

    el1
  end
end
