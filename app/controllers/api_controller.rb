class ApiController < ApplicationController

  before_filter :authorize
  after_filter :compress_output

  # The maximum area you're allowed to request, in square degrees
  MAX_REQUEST_AREA = 0.25

  def map
    response.headers["Content-Type"] = 'application/xml'
    # Figure out the bbox
    bbox = params['bbox']
    unless bbox and bbox.count(',') == 3
       report_error("The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat")
      return
    end

    bbox = bbox.split(',')

    min_lon = bbox[0].to_f
    min_lat = bbox[1].to_f
    max_lon = bbox[2].to_f
    max_lat = bbox[3].to_f

    # check the bbox is sane
    unless min_lon <= max_lon
       report_error("The minimum longitude must be less than the maximum longitude, but it wasn't")
      return
    end
    unless min_lat <= max_lat
       report_error("The minimum latitude must be less than the maximum latitude, but it wasn't")
      return
    end
	unless min_lon >= -180 && min_lat >= -90 && max_lon <= 180 && max_lat <= 90
       report_error("The latitudes must be between -90 and 90, and longitudes between -180 and 180")
      return
	end

    # check the bbox isn't too large
    requested_area = (max_lat-min_lat)*(max_lon-min_lon)
    if requested_area > MAX_REQUEST_AREA
       report_error("The maximum bbox size is " + MAX_REQUEST_AREA.to_s + ", and your request was too large. Either request a smaller area, or use planet.osm")
      return
    end

    # get all the nodes
    nodes = Node.find(:all, :conditions => ['latitude > ? AND longitude > ? AND latitude < ? AND longitude < ? AND visible = 1', min_lat, min_lon, max_lat, max_lon])

    node_ids = nodes.collect {|node| node.id }

    # (in the future, we may wish to abort here if we found too many nodes)

    # grab the segments
    segments = Array.new
    if node_ids.length > 0
      node_ids_sql = "(#{node_ids.join(',')})"
      # get the referenced segments
      segments = Segment.find_by_sql "select * from current_segments where visible = 1 and (node_a in #{node_ids_sql} or node_b in #{node_ids_sql})"
    end
    # see if we have any missing nodes
    segments_nodes = segments.collect {|segment| segment.node_a }
    segments_nodes += segments.collect {|segment| segment.node_b }

    segments_nodes.uniq!

    missing_nodes = segments_nodes - node_ids

    # get missing nodes if there are any
    nodes += Node.find(missing_nodes) if missing_nodes.length > 0

    doc = OSM::API.get_xml_doc

    # get ways
    # find which ways are needed
    segment_ids = segments.collect {|segment| segment.id }
    ways = Array.new
    if segment_ids.length > 0
      way_segments = WaySegment.find_all_by_segment_id(segment_ids)
      way_ids = way_segments.collect {|way_segment| way_segment.id }
      ways = Way.find(way_ids) # NB: doesn't pick up segments, tags from db until accessed via way.way_segments etc.
    end

    nodes.each do |node|
      doc.root << node.to_xml_node()
    end

    segments.each do |segment|
      doc.root << segment.to_xml_node()
    end 

    ways.each do |way|
      doc.root << way.to_xml_node()
    end 

    render :text => doc.to_s

  end
end
