class ApiController < ApplicationController

  def map
    bbox = params['bbox']
    unless bbox and bbox.count(',') == 3
      render :nothing => true, :status => 400
      return
    end

    bbox = bbox.split(',')

    min_lat = bbox[0].to_f
    min_lon = bbox[1].to_f
    max_lat = bbox[2].to_f
    max_lon = bbox[3].to_f

    nodes = Node.find(:all, :conditions => ['latitude > ? AND longitude > ? AND latitude < ? AND longitude < ? AND visible = 1', min_lat, min_lon, max_lat, max_lon])

    node_ids = "(#{nodes.collect {|node| node.id }})"

    segments = Segment.find(:all, :condtions => ['node_a in ? or node_b in ?', node_ids, node_ids])
    render :text => node_ids.join(',')
    return

    doc = XML::Document.new
    doc.encoding = 'UTF-8' 
    root = XML::Node.new 'osm'
    root['version'] = '0.4'
    root['generator'] = 'OpenStreetMap server'
    doc.root = root

    render :text => doc.to_s
    
    #el1 = XML::Node.new 'node'
    #el1['id'] = self.id.to_s
    #el1['lat'] = self.latitude.to_s
    #el1['lon'] = self.longitude.to_s
    #Node.split_tags(el1, self.tags)
    #el1['visible'] = self.visible.to_s
    #el1['timestamp'] = self.timestamp.xmlschema
    #root << el1
  end

end
