class Segment < ActiveRecord::Base
  require 'xml/libxml'
  set_table_name 'current_segments'

  validates_presence_of :user_id, :timestamp
  validates_inclusion_of :visible, :in => [ true, false ]
  validates_numericality_of :node_a, :node_b

  has_many :old_segments, :foreign_key => :id
  belongs_to :user

  # using belongs_to :foreign_key = 'node_*', since if use has_one :foreign_key = 'id', segment preconditions? fails checking for segment id in node table
  belongs_to :from_node, :class_name => 'Node', :foreign_key => 'node_a'
  belongs_to :to_node, :class_name => 'Node', :foreign_key => 'node_b'

  def self.from_xml(xml, create=false)
    begin
      p = XML::Parser.new
      p.string = xml
      doc = p.parse

      segment = Segment.new

      doc.find('//osm/segment').each do |pt|
        segment.node_a = pt['from'].to_i
        segment.node_b = pt['to'].to_i

        unless create
          if pt['id'] != '0'
            segment.id = pt['id'].to_i
          end
        end

        segment.visible = true

        if create
          segment.timestamp = Time.now
        else
          if pt['timestamp']
            segment.timestamp = Time.parse(pt['timestamp'])
          end
        end

        tags = []

        pt.find('tag').each do |tag|
          tags << [tag['k'],tag['v']]
        end

        tags = tags.collect { |k,v| "#{k}=#{v}" }.join(';')
        tags = '' if tags.nil?

        segment.tags = tags
      end
    rescue
      segment = nil
    end

    return segment
  end

  def save_with_history!
    Segment.transaction do
      self.timestamp = Time.now
      self.save!
      old_segment = OldSegment.from_segment(self)
      old_segment.save!
    end
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  def to_xml_node(user_display_name_cache  = nil)
    el1 = XML::Node.new 'segment'
    el1['id'] = self.id.to_s
    el1['from'] = self.node_a.to_s
    el1['to'] = self.node_b.to_s

    user_display_name_cache = {} if user_display_name_cache.nil?

    if user_display_name_cache and user_display_name_cache.key?(self.user_id)
      # use the cache if available
    elsif self.user.data_public?
      user_display_name_cache[self.user_id] = self.user.display_name
    else
      user_display_name_cache[self.user_id] = nil
    end

    el1['user'] = user_display_name_cache[self.user_id] unless user_display_name_cache[self.user_id].nil?

    Segment.split_tags(el1, self.tags)
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    return el1
  end

  def self.split_tags(el, tags)
    tags.split(';').each do |tag|
      parts = tag.split('=')
      key = ''
      val = ''
      key = parts[0].strip unless parts[0].nil?
      val = parts[1].strip unless parts[1].nil?
      if key != '' && val != ''
        el2 = XML::Node.new('tag')
        el2['k'] = key.to_s
        el2['v'] = val.to_s
        el << el2
      end
    end
  end

  def preconditions_ok?
    from_node and from_node.visible and to_node and to_node.visible
  end

end
