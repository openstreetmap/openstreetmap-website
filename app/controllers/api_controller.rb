class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :api_deny_access_handler

  authorize_resource :class => false

  before_action :check_api_readable
  before_action :setup_user_auth, :only => [:permissions]
  around_action :api_call_handle_error, :api_call_timeout

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
    rescue StandardError => err
      report_error(err.message)
      return
    end

    nodes = Node.bbox(bbox).where(:visible => true).includes(:node_tags).limit(MAX_NUMBER_OF_NODES + 1)

    node_ids = nodes.collect(&:id)
    if node_ids.length > MAX_NUMBER_OF_NODES
      report_error("You requested too many nodes (limit is #{MAX_NUMBER_OF_NODES}). Either request a smaller area, or use planet.osm")
      return
    end

    doc = OSM::API.new.get_xml_doc

    # add bounds
    doc.root << bbox.add_bounds_to(XML::Node.new("bounds"))

    # get ways
    # find which ways are needed
    ways = []
    if node_ids.empty?
      list_of_way_nodes = []
    else
      way_nodes = WayNode.where(:node_id => node_ids)
      way_ids = way_nodes.collect { |way_node| way_node.id[0] }
      ways = Way.preload(:way_nodes, :way_tags).find(way_ids)

      list_of_way_nodes = ways.collect do |way|
        way.way_nodes.collect(&:node_id)
      end
      list_of_way_nodes.flatten!
    end

    # - [0] in case some thing links to node 0 which doesn't exist. Shouldn't actually ever happen but it does. FIXME: file a ticket for this
    nodes_to_fetch = (list_of_way_nodes.uniq - node_ids) - [0]

    nodes += Node.includes(:node_tags).find(nodes_to_fetch) unless nodes_to_fetch.empty?

    visible_nodes = {}
    changeset_cache = {}
    user_display_name_cache = {}

    nodes.each do |node|
      if node.visible?
        doc.root << node.to_xml_node(changeset_cache, user_display_name_cache)
        visible_nodes[node.id] = node
      end
    end

    way_ids = []
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
    relations += Relation.relations(relations.collect(&:id)).visible

    # this "uniq" may be slightly inefficient; it may be better to first collect and output
    # all node-related relations, then find the *not yet covered* way-related ones etc.
    relations.uniq.each do |relation|
      doc.root << relation.to_xml_node(changeset_cache, user_display_name_cache)
    end

    response.headers["Content-Disposition"] = "attachment; filename=\"map.osm\""

    render :xml => doc.to_s
  end

  # Get a list of the tiles that have changed within a specified time
  # period
  def changes
    zoom = (params[:zoom] || "12").to_i

    if params.include?(:start) && params.include?(:end)
      starttime = Time.parse(params[:start])
      endtime = Time.parse(params[:end])
    else
      hours = (params[:hours] || "1").to_i.hours
      endtime = Time.now.getutc
      starttime = endtime - hours
    end

    if zoom >= 1 && zoom <= 16 &&
       endtime > starttime && endtime - starttime <= 24.hours
      mask = (1 << zoom) - 1

      tiles = Node.where(:timestamp => starttime..endtime).group("maptile_for_point(latitude, longitude, #{zoom})").count

      doc = OSM::API.new.get_xml_doc
      changes = XML::Node.new "changes"
      changes["starttime"] = starttime.xmlschema
      changes["endtime"] = endtime.xmlschema

      tiles.each do |tile, count|
        x = (tile.to_i >> zoom) & mask
        y = tile.to_i & mask

        t = XML::Node.new "tile"
        t["x"] = x.to_s
        t["y"] = y.to_s
        t["z"] = zoom.to_s
        t["changes"] = count.to_s

        changes << t
      end

      doc.root << changes

      render :xml => doc.to_s
    else
      render :plain => "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours", :status => :bad_request
    end
  end

  # External apps that use the api are able to query which permissions
  # they have. This currently returns a list of permissions granted to the current user:
  # * if authenticated via OAuth, this list will contain all permissions granted by the user to the access_token.
  # * if authenticated via basic auth all permissions are granted, so the list will contain all permissions.
  # * unauthenticated users have no permissions, so the list will be empty.
  def permissions
    @permissions = if current_token.present?
                     ClientApplication.all_permissions.select { |p| current_token.read_attribute(p) }
                   elsif current_user
                     ClientApplication.all_permissions
                   else
                     []
                   end
  end
end
