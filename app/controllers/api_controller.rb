class ApiController < ApplicationController

  skip_before_filter :verify_authenticity_token
  before_filter :check_api_readable, :except => [:capabilities]
  before_filter :setup_user_auth, :only => [:permissions]
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  # Get an XML response containing a list of tracepoints that have been uploaded
  # within the specified bounding box, and in the specified page.
  def trackpoints
    #retrieve the page number
    page = params['page'].to_s.to_i

    unless page >= 0
        report_error("Page number must be greater than or equal to 0")
        return
    end

    offset = page * TRACEPOINTS_PER_PAGE

    # Figure out the bbox
    # check boundary is sane and area within defined
    # see /config/application.yml
    begin
      bbox = BoundingBox.from_bbox_params(params)
      bbox.check_boundaries
      bbox.check_size
    rescue Exception => err
      report_error(err.message)
      return
    end

    # get all the points
    points = Tracepoint.bbox(bbox).offset(offset).limit(TRACEPOINTS_PER_PAGE).order("gpx_id DESC, trackid ASC, timestamp ASC")

    doc = XML::Document.new
    doc.encoding = XML::Encoding::UTF_8
    root = XML::Node.new 'gpx'
    root['version'] = '1.0'
    root['creator'] = 'OpenStreetMap.org'
    root['xmlns'] = "http://www.topografix.com/GPX/1/0"
    
    doc.root = root

    # initialise these variables outside of the loop so that they
    # stay in scope and don't get free'd up by the GC during the
    # loop.
    gpx_id = -1
    trackid = -1
    track = nil
    trkseg = nil
    anon_track = nil
    anon_trkseg = nil
    gpx_file = nil
    timestamps = false

    points.each do |point|
      if gpx_id != point.gpx_id
        gpx_id = point.gpx_id
        trackid = -1
        gpx_file = Trace.find(gpx_id)

        if gpx_file.trackable?
          track = XML::Node.new 'trk'
          doc.root << track
          timestamps = true

          if gpx_file.identifiable?
            track << (XML::Node.new("name") << gpx_file.name)
            track << (XML::Node.new("desc") << gpx_file.description)
            track << (XML::Node.new("url") << url_for(:controller => 'trace', :action => 'view', :display_name => gpx_file.user.display_name, :id => gpx_file.id))
          end
        else
          # use the anonymous track segment if the user hasn't allowed
          # their GPX points to be tracked.
          timestamps = false
          if anon_track.nil? 
            anon_track = XML::Node.new 'trk'
            doc.root << anon_track
          end
          track = anon_track
        end
      end
      
      if trackid != point.trackid
        if gpx_file.trackable?
          trkseg = XML::Node.new 'trkseg'
          track << trkseg
          trackid = point.trackid
        else
          if anon_trkseg.nil? 
            anon_trkseg = XML::Node.new 'trkseg'
            anon_track << anon_trkseg
          end
          trkseg = anon_trkseg
        end
      end

      trkseg << point.to_xml_node(timestamps)
    end

    response.headers["Content-Disposition"] = "attachment; filename=\"tracks.gpx\""

    render :text => doc.to_s, :content_type => "text/xml"
  end

  # This is probably the most common call of all. It is used for getting the 
  # OSM data for a specified bounding box, usually for editing. First the
  # bounding box (bbox) is checked to make sure that it is sane. All nodes 
  # are searched, then all the ways that reference those nodes are found.
  # All Nodes that are referenced by those ways are fetched and added to the list
  # of nodes.
  # Then all the relations that reference the already found nodes and ways are
  # fetched. All the nodes and ways that are referenced by those ways are then 
  # fetched. Finally all the xml is returned.
  def map
    # Figure out the bbox
    # check boundary is sane and area within defined
    # see /config/application.yml
    begin
      bbox = BoundingBox.from_bbox_params(params)
      bbox.check_boundaries
      bbox.check_size
    rescue Exception => err
      report_error(err.message)
      return
    end

    @nodes = Node.bbox(bbox).where(:visible => true).includes(:node_tags).limit(MAX_NUMBER_OF_NODES+1)

    node_ids = @nodes.collect(&:id)
    if node_ids.length > MAX_NUMBER_OF_NODES
      report_error("You requested too many nodes (limit is #{MAX_NUMBER_OF_NODES}). Either request a smaller area, or use planet.osm")
      return
    end
    if node_ids.length == 0
      render :text => "<osm version='#{API_VERSION}' generator='#{GENERATOR}'></osm>", :content_type => "text/xml"
      return
    end

    doc = OSM::API.new.get_xml_doc

    # add bounds
    doc.root << bbox.add_bounds_to(XML::Node.new 'bounds')

    # get ways
    # find which ways are needed
    ways = Array.new
    if node_ids.length > 0
      way_nodes = WayNode.where(:node_id => node_ids)
      way_ids = way_nodes.collect { |way_node| way_node.id[0] }
      ways = Way.preload(:way_nodes, :way_tags).find(way_ids)

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
      @nodes += Node.includes(:node_tags).find(nodes_to_fetch)
    end

    visible_nodes = {}
    changeset_cache = {}
    user_display_name_cache = {}

    @nodes.each do |node|
      if node.visible?
        doc.root << node.to_xml_node(changeset_cache, user_display_name_cache)
        visible_nodes[node.id] = node
      end
    end

    way_ids = Array.new
    ways.each do |way|
      if way.visible?
        doc.root << way.to_xml_node(visible_nodes, changeset_cache, user_display_name_cache)
        way_ids << way.id
      end
    end 

    relations = Relation.nodes(visible_nodes.keys).visible +
                Relation.ways(way_ids).visible

    # we do not normally return the "other" partners referenced by an relation, 
    # e.g. if we return a way A that is referenced by relation X, and there's 
    # another way B also referenced, that is not returned. But we do make 
    # an exception for cases where an relation references another *relation*; 
    # in that case we return that as well (but we don't go recursive here)
    relations += Relation.relations(relations.collect { |r| r.id }).visible

    # this "uniq" may be slightly inefficient; it may be better to first collect and output
    # all node-related relations, then find the *not yet covered* way-related ones etc.
    relations.uniq.each do |relation|
      doc.root << relation.to_xml_node(nil, changeset_cache, user_display_name_cache)
    end

    response.headers["Content-Disposition"] = "attachment; filename=\"map.osm\""

    render :text => doc.to_s, :content_type => "text/xml"
  end

  # Get a list of the tiles that have changed within a specified time
  # period
  def changes
    zoom = (params[:zoom] || '12').to_i

    if params.include?(:start) and params.include?(:end)
      starttime = Time.parse(params[:start])
      endtime = Time.parse(params[:end])
    else
      hours = (params[:hours] || '1').to_i.hours
      endtime = Time.now.getutc
      starttime = endtime - hours
    end

    if zoom >= 1 and zoom <= 16 and
       endtime > starttime and endtime - starttime <= 24.hours
      mask = (1 << zoom) - 1

      tiles = Node.where(:timestamp => starttime .. endtime).group("maptile_for_point(latitude, longitude, #{zoom})").count

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
      render :text => "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours", :status => :bad_request
    end
  end

  # External apps that use the api are able to query the api to find out some 
  # parameters of the API. It currently returns: 
  # * minimum and maximum API versions that can be used.
  # * maximum area that can be requested in a bbox request in square degrees
  # * number of tracepoints that are returned in each tracepoints page
  def capabilities
    doc = OSM::API.new.get_xml_doc

    api = XML::Node.new 'api'
    version = XML::Node.new 'version'
    version['minimum'] = "#{API_VERSION}";
    version['maximum'] = "#{API_VERSION}";
    api << version
    area = XML::Node.new 'area'
    area['maximum'] = MAX_REQUEST_AREA.to_s;
    api << area
    tracepoints = XML::Node.new 'tracepoints'
    tracepoints['per_page'] = TRACEPOINTS_PER_PAGE.to_s
    api << tracepoints
    waynodes = XML::Node.new 'waynodes'
    waynodes['maximum'] = MAX_NUMBER_OF_WAY_NODES.to_s
    api << waynodes
    changesets = XML::Node.new 'changesets'
    changesets['maximum_elements'] = Changeset::MAX_ELEMENTS.to_s
    api << changesets
    timeout = XML::Node.new 'timeout'
    timeout['seconds'] = API_TIMEOUT.to_s
    api << timeout
    status = XML::Node.new 'status'
    status['database'] = database_status.to_s
    status['api'] = api_status.to_s
    status['gpx'] = gpx_status.to_s
    api << status
    doc.root << api
    policy = XML::Node.new 'policy'
    blacklist = XML::Node.new 'imagery'
    IMAGERY_BLACKLIST.each do |url_regex| 
      xnd = XML::Node.new 'blacklist'
      xnd['regex'] = url_regex.to_s
      blacklist << xnd
    end
    policy << blacklist
    doc.root << policy

    render :text => doc.to_s, :content_type => "text/xml"
  end

  # External apps that use the api are able to query which permissions
  # they have. This currently returns a list of permissions granted to the current user:
  # * if authenticated via OAuth, this list will contain all permissions granted by the user to the access_token.
  # * if authenticated via basic auth all permissions are granted, so the list will contain all permissions.
  # * unauthenticated users have no permissions, so the list will be empty.
  def permissions
    @permissions = case
                   when current_token.present?
                     ClientApplication.all_permissions.select { |p| current_token.read_attribute(p) }
                   when @user
                     ClientApplication.all_permissions
                   else
                     []
                   end
  end
end
