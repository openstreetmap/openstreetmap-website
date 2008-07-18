class Node < ActiveRecord::Base
  require 'xml/libxml'

  include GeoRecord

  set_table_name 'current_nodes'
  
  validates_presence_of :user_id, :timestamp
  validates_inclusion_of :visible, :in => [ true, false ]
  validates_numericality_of :latitude, :longitude
  validate :validate_position

  belongs_to :user

  has_many :old_nodes, :foreign_key => :id

  has_many :way_nodes
  has_many :ways, :through => :way_nodes

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
  
      node = Node.new

      doc.find('//osm/node').each do |pt|
        node.lat = pt['lat'].to_f
        node.lon = pt['lon'].to_f

        return nil unless node.in_world?

        unless create
          if pt['id'] != '0'
            node.id = pt['id'].to_i
          end
        end

        node.visible = pt['visible'] and pt['visible'] == 'true'

        if create
          node.timestamp = Time.now
        else
          if pt['timestamp']
            node.timestamp = Time.parse(pt['timestamp'])
          end
        end

        tags = []

        pt.find('tag').each do |tag|
          tags << [tag['k'],tag['v']]
        end

        node.tags = Tags.join(tags)
      end
    rescue
      node = nil
    end

    return node
  end

  # Save this node with the appropriate OldNode object to represent it's history.
  def save_with_history!
    Node.transaction do
      self.timestamp = Time.now
      self.save!
      old_node = OldNode.from_node(self)
      old_node.save!
    end
  end

  # Turn this Node in to a complete OSM XML object with <osm> wrapper
  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  # Turn this Node in to an XML Node without the <osm> wrapper.
  def to_xml_node(user_display_name_cache = nil)
    el1 = XML::Node.new 'node'
    el1['id'] = self.id.to_s
    el1['lat'] = self.lat.to_s
    el1['lon'] = self.lon.to_s

    user_display_name_cache = {} if user_display_name_cache.nil?

    if user_display_name_cache and user_display_name_cache.key?(self.user_id)
      # use the cache if available
    elsif self.user.data_public?
      user_display_name_cache[self.user_id] = self.user.display_name
    else
      user_display_name_cache[self.user_id] = nil
    end

    el1['user'] = user_display_name_cache[self.user_id] unless user_display_name_cache[self.user_id].nil?

    Tags.split(self.tags) do |k,v|
      el2 = XML::Node.new('tag')
      el2['k'] = k.to_s
      el2['v'] = v.to_s
      el1 << el2
    end

    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    return el1
  end

  # Return the node's tags as a Hash of keys and their values
  def tags_as_hash
    hash = {}
    Tags.split(self.tags) do |k,v|
      hash[k] = v
    end
    hash
  end
end
