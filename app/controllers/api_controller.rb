class ApiController < ApplicationController

  session :off
  before_filter :check_read_availability, :except => [:capabilities]
  after_filter :compress_output

  # Help methods for checking boundary sanity and area size
  include MapBoundary

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
    min_lon, min_lat, max_lon, max_lat = sanitise_boundaries(bbox)
    # check boundary is sane and area within defined
    # see /config/application.yml
    begin
      check_boundaries(min_lon, min_lat, max_lon, max_lat)
    rescue Exception => err
      report_error(err.message)
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
      # alternatively: report_error(TEXT['boundary_parameter_required']
      report_error("The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat")
      return
    end

    bbox = bbox.split(',')

    min_lon, min_lat, max_lon, max_lat = sanitise_boundaries(bbox)

    # check boundary is sane and area within defined
    # see /config/application.yml
    begin
      check_boundaries(min_lon, min_lat, max_lon, max_lat)
    rescue Exception => err
      report_error(err.message)
      return
    end

    @nodes = Node.find_by_area(min_lat, min_lon, max_lat, max_lon, :conditions => "visible = 1", :limit => APP_CONFIG['max_number_of_nodes']+1)
    # get all the nodes, by tag not yet working, waiting for change from NickB
    # need to be @nodes (instance var) so tests in /spec can be performed
    #@nodes = Node.search(bbox, params[:tag])

    node_ids = @nodes.collect(&:id)
    if node_ids.length > APP_CONFIG['max_number_of_nodes']
      report_error("You requested too many nodes (limit is 50,000). Either request a smaller area, or use planet.osm")
      return
    end
    if node_ids.length == 0
      render :text => "<osm version='0.5'></osm>", :content_type => "text/xml"
      return
    end

    relations = Array.new

    doc = OSM::API.new.get_xml_doc

    # get ways
    # find which ways are needed
    ways = Array.new
    if node_ids.length > 0
      way_nodes = WayNode.find_all_by_node_id(node_ids)
      way_ids = way_nodes.collect { |way_node| way_node.id[0] }
      ways = Way.find(way_ids)

      list_of_way_nodes = ways.collect { |way|
        way.way_nodes.collect { |way_node| way_node.node_id }
      }
      list_of_way_nodes.flatten!

    else
      list_of_way_nodes = Array.new
    end

    # - [0] in case some thing links to node 0 which doesn't exist. Shouldn't actually ever happen but it does. FIXME: file a ticket for this
    nodes_to_fetch = (list_of_way_nodes.uniq - node_ids) - [0]

    if nodes_to_fetch.length > 0
      @nodes += Node.find(nodes_to_fetch)
    end

    visible_nodes = {}
    user_display_name_cache = {}

    @nodes.each do |node|
      if node.visible?
        doc.root << node.to_xml_node(user_display_name_cache)
        visible_nodes[node.id] = node
      end
    end

    way_ids = Array.new
    ways.each do |way|
      if way.visible?
        doc.root << way.to_xml_node(visible_nodes, user_display_name_cache)
        way_ids << way.id
      end
    end 

    relations = Relation.find_for_nodes_and_ways(visible_nodes.keys, way_ids)

    # we do not normally return the "other" partners referenced by an relation, 
    # e.g. if we return a way A that is referenced by relation X, and there's 
    # another way B also referenced, that is not returned. But we do make 
    # an exception for cases where an relation references another *relation*; 
    # in that case we return that as well (but we don't go recursive here)
    relation_ids = relations.collect { |relation| relation.id }
    if relation_ids.length > 0
        relations += Relation.find_by_sql("select e.* from current_relations e,current_relation_members em where " +
            "e.visible=1 and " +
            "em.id = e.id and em.member_type='relation' and em.member_id in (#{relation_ids.join(',')})")
    end

    # this "uniq" may be slightly inefficient; it may be better to first collect and output
    # all node-related relations, then find the *not yet covered* way-related ones etc.
    relations.uniq.each do |relation|
      doc.root << relation.to_xml_node(user_display_name_cache)
    end

    render :text => doc.to_s, :content_type => "text/xml"
    
    #exit when we have too many requests
    if @@count > MAX_COUNT
      @@count = COUNT
      
      exit!
    end
  end

  def changes
    zoom = (params[:zoom] || '12').to_i

    if params.include?(:start) and params.include?(:end)
      starttime = Time.parse(params[:start])
      endtime = Time.parse(params[:end])
    else
      hours = (params[:hours] || '1').to_i.hours
      endtime = Time.now
      starttime = endtime - hours
    end

    if zoom >= 1 and zoom <= 16 and
       endtime >= starttime and endtime - starttime <= 24.hours
      mask = (1 << zoom) - 1

      tiles = Node.count(:conditions => ["timestamp BETWEEN ? AND ?", starttime, endtime],
                         :group => "maptile_for_point(latitude, longitude, #{zoom})")

      doc = OSM::API.new.get_xml_doc
      changes = XML::Node.new 'changes'
      changes["starttime"] = starttime.xmlschema
      changes["endtime"] = endtime.xmlschema

      tiles.each do |tile, count|
        x = (tile.to_i >> zoom) & mask
        y = tile.to_i & mask

        t = XML::Node.new 'tile'
        t["x"] = x.to_s
        t["y"] = y.to_s
        t["z"] = zoom.to_s
        t["changes"] = count.to_s

        changes << t
      end

      doc.root << changes

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :bad_request
    end
  end

  def capabilities
    doc = OSM::API.new.get_xml_doc

    api = XML::Node.new 'api'
    version = XML::Node.new 'version'
    version['minimum'] = '0.5';
    version['maximum'] = '0.5';
    api << version
    area = XML::Node.new 'area'
    area['maximum'] = MAX_REQUEST_AREA.to_s;
    api << area
    
    doc.root << api

    render :text => doc.to_s, :content_type => "text/xml"
  end
end
