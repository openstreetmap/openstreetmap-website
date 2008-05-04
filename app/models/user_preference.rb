class UserPreference < ActiveRecord::Base
  set_primary_keys :user_id, :k
  belongs_to :user

  # Turn this Node in to an XML Node without the <osm> wrapper.
  def to_xml_node
    el1 = XML::Node.new 'preference'
    el1['k'] = self.k
    el1['v'] = self.v
    
    return el1
  end

end
