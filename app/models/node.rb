class Node < ActiveRecord::Base
  require 'xml/libxml'

  include GeoRecord
  include ConsistencyValidations
  include NotRedactable

  self.table_name = "current_nodes"

  belongs_to :changeset

  has_many :old_nodes, :order => :version

  has_many :way_nodes
  has_many :ways, :through => :way_nodes

  has_many :node_tags
  
  has_many :old_way_nodes
  has_many :ways_via_history, :class_name=> "Way", :through => :old_way_nodes, :source => :way

  has_many :containing_relation_members, :class_name => "RelationMember", :as => :member
  has_many :containing_relations, :class_name => "Relation", :through => :containing_relation_members, :source => :relation, :extend => ObjectFinder

  validates_presence_of :id, :on => :update
  validates_presence_of :timestamp,:version,  :changeset_id
  validates_uniqueness_of :id
  validates_inclusion_of :visible, :in => [ true, false ]
  validates_numericality_of :latitude, :longitude, :changeset_id, :version, :integer_only => true
  validates_numericality_of :id, :on => :update, :integer_only => true
  validate :validate_position
  validates_associated :changeset

  scope :visible, where(:visible => true)
  scope :invisible, where(:visible => false)

  # Sanity check the latitude and longitude and add an error if it's broken
  def validate_position
    errors.add(:base, "Node is not in the world") unless in_world?
  end

  #
  # Search for nodes matching tags within bounding_box
  #
  # Also adheres to limitations such as within max_number_of_nodes
  #
  def self.search(bounding_box, tags = {})
    # @fixme a bit of a hack to search for only visible nodes
    # couldn't think of another to add to tags condition
    #conditions_hash = tags.merge({ 'visible' => 1 })
  
    # using named placeholders http://www.robbyonrails.com/articles/2005/10/21/using-named-placeholders-in-ruby
    #keys = []
    #values = {}

    #conditions_hash.each do |key,value|
    #  keys <<  "#{key} = :#{key}"
    #  values[key.to_sym] = value
    #end 
    #conditions = keys.join(' AND ')
 
    find_by_area(bounding_box, :conditions => {:visible => true},
                       :limit => MAX_NUMBER_OF_NODES+1)
  end

  # Read in xml as text and return it's Node object representation
  def self.from_xml(xml, create=false)
    begin
      p = XML::Parser.string(xml)
      doc = p.parse

      doc.find('//osm/node').each do |pt|
        return Node.from_xml_node(pt, create)
      end
      raise OSM::APIBadXMLError.new("node", xml, "XML doesn't contain an osm/node element.")
    rescue LibXML::XML::Error, ArgumentError => ex
      raise OSM::APIBadXMLError.new("node", xml, ex.message)
    end
  end

  def self.from_xml_node(pt, create=false)
    node = Node.new
    
    raise OSM::APIBadXMLError.new("node", pt, "lat missing") if pt['lat'].nil?
    raise OSM::APIBadXMLError.new("node", pt, "lon missing") if pt['lon'].nil?
    node.lat = OSM.parse_float(pt['lat'], OSM::APIBadXMLError, "node", pt, "lat not a number")
    node.lon = OSM.parse_float(pt['lon'], OSM::APIBadXMLError, "node", pt, "lon not a number")
    raise OSM::APIBadXMLError.new("node", pt, "Changeset id is missing") if pt['changeset'].nil?
    node.changeset_id = pt['changeset'].to_i

    raise OSM::APIBadUserInput.new("The node is outside this world") unless node.in_world?

    # version must be present unless creating
    raise OSM::APIBadXMLError.new("node", pt, "Version is required when updating") unless create or not pt['version'].nil?
    node.version = create ? 0 : pt['version'].to_i

    unless create
      raise OSM::APIBadXMLError.new("node", pt, "ID is required when updating.") if pt['id'].nil?
      node.id = pt['id'].to_i
      # .to_i will return 0 if there is no number that can be parsed. 
      # We want to make sure that there is no id with zero anyway
      raise OSM::APIBadUserInput.new("ID of node cannot be zero when updating.") if node.id == 0
    end

    # We don't care about the time, as it is explicitly set on create/update/delete
    # We don't care about the visibility as it is implicit based on the action
    # and set manually before the actual delete
    node.visible = true

    # Start with no tags
    node.tags = Hash.new

    # Add in any tags from the XML
    pt.find('tag').each do |tag|
      raise OSM::APIBadXMLError.new("node", pt, "tag is missing key") if tag['k'].nil?
      raise OSM::APIBadXMLError.new("node", pt, "tag is missing value") if tag['v'].nil?
      node.add_tag_key_val(tag['k'],tag['v'])
    end

    return node
  end

  ##
  # the bounding box around a node, which is used for determining the changeset's
  # bounding box
  def bbox
    BoundingBox.new(longitude, latitude, longitude, latitude)
  end

  # Should probably be renamed delete_from to come in line with update
  def delete_with_history!(new_node, user)
    unless self.visible
      raise OSM::APIAlreadyDeletedError.new("node", new_node.id)
    end

    # need to start the transaction here, so that the database can 
    # provide repeatable reads for the used-by checks. this means it
    # shouldn't be possible to get race conditions.
    Node.transaction do
      self.lock!
      check_consistency(self, new_node, user)
      ways = Way.joins(:way_nodes).where(:visible => true, :current_way_nodes => { :node_id => id }).order(:id)
      raise OSM::APIPreconditionFailedError.new("Node #{self.id} is still used by ways #{ways.collect { |w| w.id }.join(",")}.") unless ways.empty?
      
      rels = Relation.joins(:relation_members).where(:visible => true, :current_relation_members => { :member_type => "Node", :member_id => id }).order(:id)
      raise OSM::APIPreconditionFailedError.new("Node #{self.id} is still used by relations #{rels.collect { |r| r.id }.join(",")}.") unless rels.empty?

      self.changeset_id = new_node.changeset_id
      self.tags = {}
      self.visible = false
      
      # update the changeset with the deleted position
      changeset.update_bbox!(bbox)
      
      save_with_history!
    end
  end

  def update_from(new_node, user)
    Node.transaction do
      self.lock!
      check_consistency(self, new_node, user)
      
      # update changeset first
      self.changeset_id = new_node.changeset_id
      self.changeset = new_node.changeset
      
      # update changeset bbox with *old* position first
      changeset.update_bbox!(bbox);
      
      # FIXME logic needs to be double checked
      self.latitude = new_node.latitude 
      self.longitude = new_node.longitude
      self.tags = new_node.tags
      self.visible = true
      
      # update changeset bbox with *new* position
      changeset.update_bbox!(bbox);
      
      save_with_history!
    end
  end
  
  def create_with_history(user)
    check_create_consistency(self, user)
    self.version = 0
    self.visible = true

    # update the changeset to include the new location
    changeset.update_bbox!(bbox)

    save_with_history!
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  def to_xml_node(changeset_cache = {}, user_display_name_cache = {})
    el1 = XML::Node.new 'node'
    el1['id'] = self.id.to_s
    el1['version'] = self.version.to_s
    el1['changeset'] = self.changeset_id.to_s

    if self.visible?
      el1['lat'] = self.lat.to_s
      el1['lon'] = self.lon.to_s
    end

    if changeset_cache.key?(self.changeset_id)
      # use the cache if available
    else
      changeset_cache[self.changeset_id] = self.changeset.user_id
    end

    user_id = changeset_cache[self.changeset_id]

    if user_display_name_cache.key?(user_id)
      # use the cache if available
    elsif self.changeset.user.data_public?
      user_display_name_cache[user_id] = self.changeset.user.display_name
    else
      user_display_name_cache[user_id] = nil
    end

    if not user_display_name_cache[user_id].nil?
      el1['user'] = user_display_name_cache[user_id]
      el1['uid'] = user_id.to_s
    end

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

  def tags_as_hash
    return tags
  end

  def tags
    unless @tags
      @tags = {}
      self.node_tags.each do |tag|
        @tags[tag.k] = tag.v
      end
    end
    @tags
  end

  def tags=(t)
    @tags = t 
  end 

  def add_tag_key_val(k,v)
    @tags = Hash.new unless @tags

    # duplicate tags are now forbidden, so we can't allow values
    # in the hash to be overwritten.
    raise OSM::APIDuplicateTagsError.new("node", self.id, k) if @tags.include? k

    @tags[k] = v
  end

  ##
  # are the preconditions OK? this is mainly here to keep the duck
  # typing interface the same between nodes, ways and relations.
  def preconditions_ok?
    in_world?
  end

  ##
  # dummy method to make the interfaces of node, way and relation
  # more consistent.
  def fix_placeholders!(id_map, placeholder_id = nil)
    # nodes don't refer to anything, so there is nothing to do here
  end
  
  private

  def save_with_history!
    t = Time.now.getutc
    Node.transaction do
      self.version += 1
      self.timestamp = t
      self.save!

      # Create a NodeTag
      tags = self.tags
      NodeTag.delete_all(:node_id => self.id)
      tags.each do |k,v|
        tag = NodeTag.new
        tag.node_id = self.id
        tag.k = k 
        tag.v = v 
        tag.save!
      end 

      # Create an OldNode
      old_node = OldNode.from_node(self)
      old_node.timestamp = t
      old_node.save_with_dependencies!

      # tell the changeset we updated one element only
      changeset.add_changes! 1

      # save the changeset in case of bounding box updates
      changeset.save!
    end
  end
  
end
