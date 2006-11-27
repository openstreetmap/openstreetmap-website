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
    t = Time.now
    self.timestamp = t
    self.save
    
    self.tags.each do |k,v|
      tag = OldWayTag.new
      tag.k = k
      tag.v = v
      tag.id = self.id
      tag.save
    end

    i = 0
    self.segs.each do |n|
      seg = OldWaySegment.new
      seg.id = self.id
      seg.segment_id = n
      seg.sequence_id = i
      seg.save
      i += 1
    end

    old_way = OldWay.from_way(self)
    old_way.save
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

end
