class Way < ActiveRecord::Base
  require 'xml/libxml'
  
  belongs_to :user

  has_many :way_segments, :foreign_key => 'id', :order => 'sequence_id'
  has_many :way_tags, :foreign_key => 'id'

  has_many :old_ways, :foreign_key => 'id', :order => 'version'

  set_table_name 'current_ways'

  def self.from_xml(xml, create=false)
    begin
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
    rescue
      way = nil
    end

    return way
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  def to_xml_node(visible_segments = nil, user_display_name_cache = nil)
    el1 = XML::Node.new 'way'
    el1['id'] = self.id.to_s
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema

    user_display_name_cache = {} if user_display_name_cache.nil?
    
    if user_display_name_cache and user_display_name_cache.key?(self.user_id)
      # use the cache if available
    elsif self.user.data_public?
      user_display_name_cache[self.user_id] = self.user.display_name
    else
      user_display_name_cache[self.user_id] = nil
    end

    el1['user'] = user_display_name_cache[self.user_id] unless user_display_name_cache[self.user_id].nil?

    # make sure segments are output in sequence_id order
    ordered_segments = []
    self.way_segments.each do |seg|
      if visible_segments
        # if there is a list of visible segments then use that to weed out deleted segments
        if visible_segments[seg.segment_id]
          ordered_segments[seg.sequence_id] = seg.segment_id.to_s
        end
      else
        # otherwise, manually go to the db to check things
        if seg.segment.visible? and seg.segment.from_node.visible? and seg.segment.to_node.visible?
          ordered_segments[seg.sequence_id] = seg.segment_id.to_s
        end
      end
    end

    ordered_segments.each do |seg_id|
      if seg_id and seg_id != '0'
        e = XML::Node.new 'seg'
        e['id'] = seg_id
        el1 << e
      end
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
    unless @segs
        @segs = Array.new
        self.way_segments.each do |seg|
            @segs += [seg.segment_id]
        end
    end
    @segs
  end

  def tags
    unless @tags
        @tags = Hash.new
        self.way_tags.each do |tag|
            @tags[tag.k] = tag.v
        end
    end
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
    begin
      Way.transaction do
        t = Time.now
        self.timestamp = t
        self.save!

        tags = self.tags

        WayTag.delete_all(['id = ?', self.id])

        tags.each do |k,v|
          tag = WayTag.new
          tag.k = k
          tag.v = v
          tag.id = self.id
          tag.save!
        end

        segs = self.segs

        WaySegment.delete_all(['id = ?', self.id])

        i = 1
        segs.each do |n|
          seg = WaySegment.new
          seg.id = self.id
          seg.segment_id = n
          seg.sequence_id = i
          seg.save!
          i += 1
        end

        old_way = OldWay.from_way(self)
        old_way.timestamp = t
        old_way.save_with_dependencies!
      end

      return true
    rescue
      return nil
    end
  end

  def preconditions_ok?
    return false if self.segs.empty?
    self.segs.each do |n|
      segment = Segment.find(:first, :conditions => ["id = ?", n])
      unless segment and segment.visible and segment.preconditions_ok?
        return false
      end
    end
    return true
  end

end
