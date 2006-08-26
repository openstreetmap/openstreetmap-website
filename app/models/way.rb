class Way < ActiveRecord::Base
  require 'xml/libxml'
  
  belongs_to :user
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

  def segs
    @segs = Array.new unless @segs
    @segs
  end

  def tags
    @tags = Hash.new unless @tags
    @tags
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

    old_way = OldWay.from_way(self)
    old_way.save
  end

end
