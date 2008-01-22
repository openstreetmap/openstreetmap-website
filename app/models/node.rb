class Node < GeoRecord
  require 'xml/libxml'

  set_table_name 'current_nodes'
  
  validates_presence_of :user_id, :timestamp
  validates_inclusion_of :visible, :in => [ true, false ]
  validates_numericality_of :latitude, :longitude
  validate :validate_position

  has_many :old_nodes, :foreign_key => :id
  belongs_to :user
 
  def validate_position
    errors.add_to_base("Node is not in the world") unless in_world?
  end

  def in_world?
    return false if self.lat < -90 or self.lat > 90
    return false if self.lon < -180 or self.lon > 180
    return true
  end

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

  def save_with_history!
    Node.transaction do
      self.timestamp = Time.now
      self.save!
      old_node = OldNode.from_node(self)
      old_node.save!
    end
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

  def tags_as_hash
    hash = {}
    Tags.split(self.tags) do |k,v|
      hash[k] = v
    end
    hash
  end

end
