class ApiController < ApplicationController

  def map
    # Figure out the bbox
    bbox = params['bbox']
    unless bbox and bbox.count(',') == 3
      render :nothing => true, :status => 400
      return
    end

    bbox = bbox.split(',')

    min_lon = bbox[0].to_f
    min_lat = bbox[1].to_f
    max_lon = bbox[2].to_f
    max_lat = bbox[3].to_f

    # get all the nodes
    nodes = Node.find(:all, :conditions => ['latitude > ? AND longitude > ? AND latitude < ? AND longitude < ? AND visible = 1', min_lat, min_lon, max_lat, max_lon])

    node_ids = nodes.collect {|node| node.id }
    node_ids_sql = "(#{node_ids.join(',')})"

    # get the referenced segments
    segments = Segment.find_by_sql "select * from segments where node_a in #{node_ids_sql} or node_b in #{node_ids_sql}"

    # see if we have nay missing nodes
    segments_nodes = segments.collect {|segment| segment.node_a }
    segments_nodes += segments.collect {|segment| segment.node_b }

    segments_nodes.uniq!

    missing_nodes = segments_nodes - node_ids

    # get missing nodes if there are any
    nodes += Node.find(missing_nodes) if missing_nodes.length > 0

    doc = XML::Document.new
    doc.encoding = 'UTF-8' 
    root = XML::Node.new 'osm'
    root['version'] = '0.4'
    root['generator'] = 'OpenStreetMap server'
    doc.root = root
 
    nodes.each do |node|
      root << node.to_xml_node()
    end

    segments.each do |segment|
      root << segment.to_xml_node()
    end 

    render :text => doc.to_s

  end
end
