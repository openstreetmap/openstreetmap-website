class Node < ActiveRecord::Base
  require 'xml/libxml'

  include GeoRecord
  include ConsistencyValidations

  set_table_name 'current_nodes'

  validates_presence_of :changeset_id, :timestamp
  validates_inclusion_of :visible, :in => [ true, false ]
  validates_numericality_of :latitude, :longitude
  validate :validate_position

  belongs_to :changeset

  has_many :old_nodes, :foreign_key => :id

  has_many :way_nodes
  has_many :ways, :through => :way_nodes

  has_many :node_tags, :foreign_key => :id
  
  has_many :old_way_nodes
  has_many :ways_via_history, :class_name=> "Way", :through => :old_way_nodes, :source => :way

  has_many :containing_relation_members, :class_name => "RelationMember", :as => :member
  has_many :containing_relations, :class_name => "Relation", :through => :containing_relation_members, :source => :relation, :extend => ObjectFinder

  # Sanity check the latitude and longitude and add an error if it's broken
  def validate_position
    errors.add_to_base("Node is not in the world") unless in_world?
  end

  #
  # Search for nodes matching tags within bounding_box
  #
  # Also adheres to limitations such as within max_number_of_nodes
  #
  def self.search(bounding_box, tags = {})
    min_lon, min_lat, max_lon, max_lat = *bounding_box
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
 
    find_by_area(min_lat, min_lon, max_lat, max_lon,
                    :conditions => 'visible = 1',
                    :limit => APP_CONFIG['max_number_of_nodes']+1)  
  end

  # Read in xml as text and return it's Node object representation
  def self.from_xml(xml, create=false)
    begin
      p = XML::Parser.new
      p.string = xml
      doc = p.parse

      doc.find('//osm/node').each do |pt|
        return Node.from_xml_node(pt, create)
      end
    rescue
      return nil
    end
  end

  def self.from_xml_node(pt, create=false)
    node = Node.new
    
    node.lat = pt['lat'].to_f
    node.lon = pt['lon'].to_f
    node.changeset_id = pt['changeset'].to_i

    return nil unless node.in_world?

    # version must be present unless creating
    return nil unless create or not pt['version'].nil?
    node.version = pt['version'].to_i

    unless create
      if pt['id'] != '0'
        node.id = pt['id'].to_i
      end
    end

    # visible if it says it is, or as the default if the attribute
    # is missing.
    node.visible = pt['visible'].nil? or pt['visible'] == 'true'

    if create
      node.timestamp = Time.now
    else
      if pt['timestamp']
        node.timestamp = Time.parse(pt['timestamp'])
      end
    end

    tags = []

    pt.find('tag').each do |tag|
      node.add_tag_key_val(tag['k'],tag['v'])
    end

    return node
  end

  ##
  # the bounding box around a node
  def bbox
    [ longitude, latitude, longitude, latitude ]
  end

  def save_with_history!
    t = Time.now
    Node.transaction do
      self.version += 1
      self.timestamp = t
      self.save!

      # Create a NodeTag
      tags = self.tags
      NodeTag.delete_all(['id = ?', self.id])
      tags.each do |k,v|
        tag = NodeTag.new
        tag.k = k 
        tag.v = v 
        tag.id = self.id
        tag.save!
      end 

      # Create an OldNode
      old_node = OldNode.from_node(self)
      old_node.timestamp = t
      old_node.save_with_dependencies!

      # save the changeset in case of bounding box updates
      changeset.save!
    end
  end

  # Should probably be renamed delete_from to come in line with update
  def delete_with_history!(new_node, user)
    if self.visible
      check_consistency(self, new_node, user)
      if WayNode.find(:first, :joins => "INNER JOIN current_ways ON current_ways.id = current_way_nodes.id", :conditions => [ "current_ways.visible = 1 AND current_way_nodes.node_id = ?", self.id ])
        raise OSM::APIPreconditionFailedError.new
      elsif RelationMember.find(:first, :joins => "INNER JOIN current_relations ON current_relations.id=current_relation_members.id", :conditions => [ "visible = 1 AND member_type='node' and member_id=? ", self.id])
        raise OSM::APIPreconditionFailedError.new
      else
        self.changeset_id = new_node.changeset_id
        self.visible = 0

        # update the changeset with the deleted position
        changeset.update_bbox!(bbox)

        save_with_history!
      end
    else
      raise OSM::APIAlreadyDeletedError.new
    end
  end

  def update_from(new_node, user)
    check_consistency(self, new_node, user)

    # update changeset with *old* position first
    changeset.update_bbox!(bbox);

    # FIXME logic needs to be double checked
    self.changeset_id = new_node.changeset_id
    self.latitude = new_node.latitude 
    self.longitude = new_node.longitude
    self.tags = new_node.tags
    self.visible = true

    # update changeset with *new* position
    changeset.update_bbox!(bbox);

    save_with_history!
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

  def to_xml_node(user_display_name_cache = nil)
    el1 = XML::Node.new 'node'
    el1['id'] = self.id.to_s
    el1['lat'] = self.lat.to_s
    el1['lon'] = self.lon.to_s
    el1['version'] = self.version.to_s
    el1['changeset'] = self.changeset_id.to_s
    
    user_display_name_cache = {} if user_display_name_cache.nil?

    if user_display_name_cache and user_display_name_cache.key?(self.changeset.user_id)
      # use the cache if available
    elsif self.changeset.user.data_public?
      user_display_name_cache[self.changeset.user_id] = self.changeset.user.display_name
    else
      user_display_name_cache[self.changeset.user_id] = nil
    end

    el1['user'] = user_display_name_cache[self.changeset.user_id] unless user_display_name_cache[self.changeset.user_id].nil?

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
    raise OSM::APIDuplicateTagsError.new if @tags.include? k

    @tags[k] = v
  end

  ##
  # dummy method to make the interfaces of node, way and relation
  # more consistent.
  def fix_placeholders!(id_map)
    # nodes don't refer to anything, so there is nothing to do here
  end

end
