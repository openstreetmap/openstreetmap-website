class Segment < ActiveRecord::Base
  require 'xml/libxml'
  set_table_name 'current_segments'

  validates_numericality_of :segment_a
  validates_numericality_of :segment_b
  # FIXME validate a nd b exist and are visible

  has_many :old_segments, :foreign_key => :id
  belongs_to :user


  def self.from_xml(xml, create=false)
    p = XML::Parser.new
    p.string = xml
    doc = p.parse

    segment = Segment.new

    doc.find('//osm/segment').each do |pt|

      segment.segment_a = pt['from'].to_i
      segment.segment_b = pt['to'].to_i

      if pt['id'] != '0'
        segment.id = pt['id'].to_i
      end

      segment.visible = pt['visible'] == '1'

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
    return segment
  end

  def save_with_history
    begin
      Segment.transaction do
        old_segment = OldSegment.from_segment(self)
        self.save
        old_segment.save
      end
      return true
    rescue Exception => ex
      return nil
    end
  end

  def to_xml
    doc = XML::Document.new
    doc.encoding = 'UTF-8' 
    root = XML::Segment.new 'osm'
    root['version'] = '0.4'
    root['generator'] = 'OpenStreetMap server'
    doc.root = root
    el1 = XML::Segment.new 'segment'
    el1['id'] = self.id.to_s
    el1['lat'] = self.latitude.to_s
    el1['lon'] = self.longitude.to_s
    split_tags(el1, self.tags)
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    root << el1
    return doc
  end

  private
  def split_tags(el, tags)
    tags.split(';').each do |tag|
      parts = tag.split('=')
      key = ''
      val = ''
      key = parts[0].strip unless parts[0].nil?
      val = parts[1].strip unless parts[1].nil?
      if key != '' && val != ''
        el2 = Segment.new('tag')
        el2['k'] = key.to_s
        el2['v'] = val.to_s
        el << el2
      end
    end
  end


end
