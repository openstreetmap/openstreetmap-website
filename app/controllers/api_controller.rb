class ApiController < ApplicationController

  session :off
  before_filter :check_read_availability, :except => [:capabilities]
  after_filter :compress_output

  #COUNT is the number of map requests to allow before exiting and starting a new process
  @@count = COUNT

  # The maximum area you're allowed to request, in square degrees
  MAX_REQUEST_AREA = 0.25


  # Number of GPS trace/trackpoints returned per-page
  TRACEPOINTS_PER_PAGE = 5000
  
  def trackpoints
    @@count+=1
    #retrieve the page number
    page = params['page'].to_i
    unless page
        page = 0;
    end

    unless page >= 0
        report_error("Page number must be greater than or equal to 0")
        return
    end

    offset = page * TRACEPOINTS_PER_PAGE

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

    # get all the points
    points = Tracepoint.find_by_area(min_lat, min_lon, max_lat, max_lon, :offset => offset, :limit => TRACEPOINTS_PER_PAGE, :order => "timestamp DESC" )

    doc = XML::Document.new
    doc.encoding = 'UTF-8'
    root = XML::Node.new 'gpx'
    root['version'] = '1.0'
    root['creator'] = 'OpenStreetMap.org'
    root['xmlns'] = "http://www.topografix.com/GPX/1/0/"
    
    doc.root = root

    track = XML::Node.new 'trk'
    doc.root << track

    trkseg = XML::Node.new 'trkseg'
    track << trkseg

    points.each do |point|
      trkseg << point.to_xml_node()
    end

    #exit when we have too many requests
    if @@count > MAX_COUNT
      render :text => doc.to_s, :content_type => "text/xml"
      @@count = COUNT
      exit!
    end

    render :text => doc.to_s, :content_type => "text/xml"

  end

  def map
    GC.start
    @@count+=1

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
    nodes = Node.find(:all, :conditions => ['latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ? AND visible = 1', min_lat, max_lat, min_lon, max_lon])

    node_ids = nodes.collect {|node| node.id }

    if node_ids.length > 50_000
      report_error("You requested too many nodes (limit is 50,000). Either request a smaller area, or use planet.osm")
      return
    end

    if node_ids.length == 0
      render :text => "<osm version='0.4'></osm>", :content_type => "text/xml"
      return
    end

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

    doc = OSM::API.new.get_xml_doc

    # get ways
    # find which ways are needed
    segment_ids = segments.collect {|segment| segment.id }
    ways = Array.new
    if segment_ids.length > 0
      way_segments = WaySegment.find_all_by_segment_id(segment_ids)
      way_ids = way_segments.collect {|way_segment| way_segment.id }
      ways = Way.find(way_ids) # NB: doesn't pick up segments, tags from db until accessed via way.way_segments etc.

      # seg_ids = way_segments.collect {|way_segment| way_segment.segment_id }

      list_of_way_segs = ways.collect {|way| way.way_segments}
      list_of_way_segs.flatten!

      list_of_way_segments = list_of_way_segs.collect { |way_seg| way_seg.segment_id }

	else
	  list_of_way_segments = Array.new
    end

    # - [0] in case some thing links to segment 0 which doesn't exist. Shouldn't actually ever happen but it does. FIXME: file a ticket for this
    segments_to_fetch = (list_of_way_segments.uniq - segment_ids) - [0]

    if segments_to_fetch.length > 0
      segments += Segment.find(segments_to_fetch)
    end

    # get more nodes
    #

    segments_nodes = segments.collect {|segment| segment.node_a }
    segments_nodes += segments.collect {|segment| segment.node_b }

    node_ids_a = nodes.collect {|node| node.id }

    nodes_to_get = segments_nodes - node_ids_a
    nodes += Node.find(nodes_to_get) if nodes_to_get.length > 0

    visible_nodes = {}
    user_display_name_cache = {}

    nodes.each do |node|
      if node.visible?
        doc.root << node.to_xml_node(user_display_name_cache)
        visible_nodes[node.id] = node
      end
    end

    visible_segments = {}

    segments.each do |segment|
      if visible_nodes[segment.node_a] and visible_nodes[segment.node_b] and segment.visible?
        doc.root << segment.to_xml_node(user_display_name_cache) 
        visible_segments[segment.id] = segment
      end
    end

    ways.each do |way|
      doc.root << way.to_xml_node(visible_segments, user_display_name_cache) if way.visible?
    end 

    render :text => doc.to_s, :content_type => "text/xml"
    
    #exit when we have too many requests
    if @@count > MAX_COUNT
      @@count = COUNT
      
      exit!
    end
  end

  def capabilities
    doc = OSM::API.new.get_xml_doc

    api = XML::Node.new 'api'
    version = XML::Node.new 'version'
    version['minimum'] = '0.4';
    version['maximum'] = '0.4';
    api << version
    area = XML::Node.new 'area'
    area['maximum'] = MAX_REQUEST_AREA.to_s;
    api << area
    
    doc.root << api

    render :text => doc.to_s, :content_type => "text/xml"
  end
end
