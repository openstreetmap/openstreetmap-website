class OldWay < ActiveRecord::Base
  set_table_name 'ways'

  belongs_to :user

  def self.from_way(way)
    old_way = OldWay.new
    old_way.user_id = way.user_id
    old_way.timestamp = way.timestamp
    old_way.id = way.id
    old_way.segs = way.segs
    old_way.tags = way.tags
    return old_way
  end

  def save_with_dependencies

    # dont touch this unless you really have figured out why it's called
    # (Rails doesn't deal well with the old ways table (called 'ways') because
    # it doesn't have a unique key. It knows how to insert and auto_increment
    # id and get it back but we have that and we want to get the 'version' back
    # we could add another column but thats a lot of data. No, set_primary_key
    # doesn't work either.
    save()
    clear_aggregation_cache
    clear_association_cache
    @attributes.update(OldWay.find(:first, :conditions => ['id = ? AND timestamp = ?', self.id, self.timestamp]).instance_variable_get('@attributes'))

    # ok, you can touch from here on

    self.tags.each do |k,v|
      tag = OldWayTag.new
      tag.k = k
      tag.v = v
      tag.id = self.id
      tag.version = self.version
      tag.save
    end

    i = 0
    self.segs.each do |n|
      seg = OldWaySegment.new
      seg.id = self.id
      seg.segment_id = n
      seg.version = self.version
      seg.save
    end
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

#  has_many :way_segments, :class_name => 'OldWaySegment', :foreign_key => 'id'
#  has_many :way_tags, :class_name => 'OldWayTag', :foreign_key => 'id'

  def old_segments
    OldWaySegment.find(:all, :conditions => ['id = ? AND version = ?', self.id, self.version])    
  end

  def old_tags
    OldWayTag.find(:all, :conditions => ['id = ? AND version = ?', self.id, self.version])    
  end

  def to_xml_node
    el1 = XML::Node.new 'way'
    el1['id'] = self.id.to_s
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    el1['user'] = self.user.display_name if self.user.data_public?
    
    self.old_segments.each do |seg| # FIXME need to make sure they come back in the right order
      e = XML::Node.new 'seg'
      e['id'] = seg.segment_id.to_s
      el1 << e
    end
 
    self.old_tags.each do |tag|
      e = XML::Node.new 'tag'
      e['k'] = tag.k
      e['v'] = tag.v
      el1 << e
    end
    return el1
  end 
end
