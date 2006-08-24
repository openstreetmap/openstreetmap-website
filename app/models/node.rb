class Node < ActiveRecord::Base
  require 'xml/libxml'
  set_table_name 'current_nodes'

  validates_numericality_of :latitude
  validates_numericality_of :longitude
  # FIXME validate lat and lon within the world

  has_many :old_nodes, :foreign_key => :id
  belongs_to :user


  def self.from_xml(xml, create=false)
    p = XML::Parser.new
    p.string = xml
    doc = p.parse

    node = Node.new

    doc.find('//osm/node').each do |pt|


      node.latitude = pt['lat'].to_f
      node.longitude = pt['lon'].to_f

      if node.latitude > 90 or node.latitude < -90 or node.longitude > 180 or node.longitude < -180
        return nil
      end

      if pt['id'] != '0'
        node.id = pt['id'].to_i
      end

      node.visible = pt['visible'] == '1'

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

      tags = tags.collect { |k,v| "#{k}=#{v}" }.join(';')
      tags = '' if tags.nil?

      node.tags = tags

    end
    return node
  end

  def save_with_history
    begin
      Node.transaction do
        old_node = OldNode.from_node(self)
        self.save
        old_node.save
      end
      return true
    rescue Exception => ex
      return nil
    end
  end

  def to_xml
    doc = XML::Document.new
    doc.encoding = 'UTF-8' 
    root = XML::Node.new 'osm'
    root['version'] = '0.4'
    root['generator'] = 'OpenStreetMap server'
    doc.root = root
    el1 = XML::Node.new 'node'
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
        el2 = Node.new('tag')
        el2['k'] = key.to_s
        el2['v'] = val.to_s
        el << el2
      end
    end
  end
end
