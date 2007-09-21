class OldNode < ActiveRecord::Base
  set_table_name 'nodes'
  
  validates_presence_of :user_id, :timestamp
  validates_inclusion_of :visible, :in => [ true, false ]
  validates_numericality_of :latitude, :longitude
  validate :validate_position

  belongs_to :user
 
  before_save :update_tile

  def self.find_by_area(minlat, minlon, maxlat, maxlon, options)
    self.with_scope(:find => {:conditions => OSM.sql_for_area(minlat, minlon, maxlat, maxlon)}) do
      return self.find(:all, options)
    end
  end

  def update_tile
    self.tile = QuadTile.tile_for_point(lat, lon)
  end

  def lat=(l)
    self.latitude = (l * 10000000).round
  end

  def lon=(l)
    self.longitude = (l * 10000000).round
  end

  def lat
    return self.latitude.to_f / 10000000
  end

  def lon
    return self.longitude.to_f / 10000000
  end

  def validate_position
    errors.add_to_base("Node is not in the world") unless in_world?
  end

  def in_world?
    return false if self.lat < -90 or self.lat > 90
    return false if self.lon < -180 or self.lon > 180
    return true
  end

  def self.from_node(node)
    old_node = OldNode.new
    old_node.latitude = node.latitude
    old_node.longitude = node.longitude
    old_node.visible = node.visible
    old_node.tags = node.tags
    old_node.timestamp = node.timestamp
    old_node.user_id = node.user_id
    old_node.id = node.id
    return old_node
  end

  def to_xml_node
    el1 = XML::Node.new 'node'
    el1['id'] = self.id.to_s
    el1['lat'] = self.lat.to_s
    el1['lon'] = self.lon.to_s
    el1['user'] = self.user.display_name if self.user.data_public?
    Node.split_tags(el1, self.tags)
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    return el1
  end
end
