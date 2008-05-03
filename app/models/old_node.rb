class OldNode < GeoRecord
  set_table_name 'nodes'
  
  validates_presence_of :user_id, :timestamp
  validates_inclusion_of :visible, :in => [ true, false ]
  validates_numericality_of :latitude, :longitude
  validate :validate_position

  belongs_to :user
 
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
    old_node.version = node.version
    return old_node
  end

  def to_xml_node
    el1 = XML::Node.new 'node'
    el1['id'] = self.id.to_s
    el1['lat'] = self.lat.to_s
    el1['lon'] = self.lon.to_s
    el1['user'] = self.user.display_name if self.user.data_public?

    self.tags.each do |k,v|
      el2 = XML::Node.new('tag')
      el2['k'] = k.to_s
      el2['v'] = v.to_s
      el1 << el2
    end

    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    return el1
  end

  def save_with_dependencies!
    save!
    #not sure whats going on here
    clear_aggregation_cache
    clear_association_cache
    #ok from here
    @attributes.update(OldNode.find(:first, :conditions => ['id = ? AND timestamp = ?', self.id, self.timestamp]).instance_variable_get('@attributes'))
   
    self.tags.each do |k,v|
      tag = OldNodeTag.new
      tag.k = k
      tag.v = v
      tag.id = self.id
      tag.version = self.version
      tag.save!
    end
  end

  def tags
    unless @tags
        @tags = Hash.new
        OldNodeTag.find(:all, :conditions => ["id = ? AND version = ?", self.id, self.version]).each do |tag|
            @tags[tag.k] = tag.v
        end
    end
    @tags = Hash.new unless @tags
    @tags
  end

  def tags=(t)
    @tags = t 
  end 

end
