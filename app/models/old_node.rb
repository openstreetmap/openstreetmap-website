class OldNode < ActiveRecord::Base
  include GeoRecord
  include ConsistencyValidations

  self.table_name = "nodes"
  self.primary_keys = "node_id", "version"

  validates_presence_of :changeset_id, :timestamp
  validates_inclusion_of :visible, :in => [ true, false ]
  validates_numericality_of :latitude, :longitude
  validate :validate_position
  validates_associated :changeset

  belongs_to :changeset
 
  def validate_position
    errors.add(:base, "Node is not in the world") unless in_world?
  end

  def self.from_node(node)
    old_node = OldNode.new
    old_node.latitude = node.latitude
    old_node.longitude = node.longitude
    old_node.visible = node.visible
    old_node.tags = node.tags
    old_node.timestamp = node.timestamp
    old_node.changeset_id = node.changeset_id
    old_node.node_id = node.id
    old_node.version = node.version
    return old_node
  end
  
  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  def to_xml_node
    el1 = XML::Node.new 'node'
    el1['id'] = self.node_id.to_s
    el1['lat'] = self.lat.to_s
    el1['lon'] = self.lon.to_s
    el1['changeset'] = self.changeset.id.to_s
    if self.changeset.user.data_public?
      el1['user'] = self.changeset.user.display_name
      el1['uid'] = self.changeset.user.id.to_s
    end

    self.tags.each do |k,v|
      el2 = XML::Node.new('tag')
      el2['k'] = k.to_s
      el2['v'] = v.to_s
      el1 << el2
    end

    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    el1['version'] = self.version.to_s
    return el1
  end

  def save_with_dependencies!
    save!
    #not sure whats going on here
    clear_aggregation_cache
    clear_association_cache
    #ok from here
    @attributes.update(OldNode.where(:node_id => self.node_id, :timestamp => self.timestamp, :version => self.version).first.instance_variable_get('@attributes'))
   
    self.tags.each do |k,v|
      tag = OldNodeTag.new
      tag.k = k
      tag.v = v
      tag.node_id = self.node_id
      tag.version = self.version
      tag.save!
    end
  end

  def tags
    unless @tags
      @tags = Hash.new
      OldNodeTag.where(:node_id => self.node_id, :version => self.version).each do |tag|
        @tags[tag.k] = tag.v
      end
    end
    @tags = Hash.new unless @tags
    @tags
  end

  def tags=(t)
    @tags = t 
  end

  def tags_as_hash 
    return self.tags
  end 
 
  # Pretend we're not in any ways 
  def ways 
    return [] 
  end 
 
  # Pretend we're not in any relations 
  def containing_relation_members 
    return [] 
  end 
end
