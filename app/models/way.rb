class Way < ActiveRecord::Base
  require 'xml/libxml'
  
  belongs_to :user

  has_many :way_segments, :foreign_key => 'id'
  has_many :way_tags, :foreign_key => 'id'

  has_many :old_ways, :foreign_key => :id

  set_table_name 'current_ways'

  def self.from_xml(xml, create=false)
    p = XML::Parser.new
    p.string = xml
    doc = p.parse

    way = Way.new

    doc.find('//osm/way').each do |pt|
      if !create and pt['id'] != '0'
        way.id = pt['id'].to_i
      end

      if create
        way.timestamp = Time.now
        way.visible = true
      else
        if pt['timestamp']
          way.timestamp = Time.parse(pt['timestamp'])
        end
      end

      pt.find('tag').each do |tag|
        way.add_tag_keyval(tag['k'], tag['v'])
      end

      pt.find('seg').each do |seg|
        way.add_seg_num(seg['id'])
      end

    end

    return way
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  def to_xml_node
    el1 = XML::Node.new 'way'
    el1['id'] = self.id.to_s
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    el1['user'] = self.user.display_name if self.user.data_public?
    # make sure segments are output in sequence_id order
    ordered_segments = []
    self.way_segments.each do |seg| 
      ordered_segments[seg.sequence_id] = seg.segment_id.to_s
    end
    ordered_segments.each do |seg_id|
      e = XML::Node.new 'seg'
      e['id'] = seg_id
      el1 << e
    end
 
    self.way_tags.each do |tag|
      e = XML::Node.new 'tag'
      e['k'] = tag.k
      e['v'] = tag.v
      el1 << e
    end
    return el1
  end 


  def segs
    @segs = Array.new unless @segs
    @segs
  end

  def tags
    @tags = Hash.new unless @tags
    @tags
  end

  def segs=(s)
    @segs = s
  end

  def tags=(t)
    @tags = t
  end

  def add_seg_num(n)
    @segs = Array.new unless @segs
    @segs << n.to_i
  end

  def add_tag_keyval(k, v)
    @tags = Hash.new unless @tags
    @tags[k] = v
  end

  def save_with_history
    t = Time.now
    self.timestamp = t
    self.save
    
    WayTag.delete_all(['id = ?', self.id])

    self.tags.each do |k,v|
      tag = WayTag.new
      tag.k = k
      tag.v = v
      tag.id = self.id
      tag.save
    end

    WaySegment.delete_all(['id = ?', self.id])
    
    i = 0
    self.segs.each do |n|
      seg = WaySegment.new
      seg.id = self.id
      seg.segment_id = n
      seg.sequence_id = i
      seg.save
      i += 1
    end

    old_way = OldWay.from_way(self)
    old_way.timestamp = t
    old_way.save_with_dependencies
  end

  def preconditions_ok?
    self.segs.each do |n|
      segment = Segment.find(n)
      unless segment and segment.visible and segment.preconditions_ok?
        return false
      end
    end
    return true
  end

end
