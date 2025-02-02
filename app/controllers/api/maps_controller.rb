module Api
  class MapsController < ApiController
    authorize_resource :class => false

    before_action :set_request_formats

    # This is probably the most common call of all. It is used for getting the
    # OSM data for a specified bounding box, usually for editing. First the
    # bounding box (bbox) is checked to make sure that it is sane. All nodes
    # are searched, then all the ways that reference those nodes are found.
    # All Nodes that are referenced by those ways are fetched and added to the list
    # of nodes.
    # Then all the relations that reference the already found nodes and ways are
    # fetched. All the nodes and ways that are referenced by those ways are then
    # fetched. Finally all the xml is returned.
    def show
      # Figure out the bbox
      # check boundary is sane and area within defined
      # see /config/application.yml
      begin
        raise OSM::APIBadUserInput, "The parameter bbox is required" unless params[:bbox]

        @bounds = BoundingBox.from_bbox_params(params)
        @bounds.check_boundaries
        @bounds.check_size
      rescue StandardError => e
        report_error(e.message)
        return
      end

      nodes = Node.bbox(@bounds).where(:visible => true).includes(:node_tags).limit(Settings.max_number_of_nodes + 1)

      node_ids = nodes.collect(&:id)
      if node_ids.length > Settings.max_number_of_nodes
        report_error("You requested too many nodes (limit is #{Settings.max_number_of_nodes}). Either request a smaller area, or use planet.osm")
        return
      end

      # get ways
      # find which ways are needed
      ways = []
      if node_ids.empty?
        list_of_way_nodes = []
      else
        way_nodes = WayNode.where(:node_id => node_ids)
        way_ids = way_nodes.collect { |way_node| way_node.id[0] }
        ways = Way.preload(:way_nodes, :way_tags).find(way_ids)

        list_of_way_nodes = ways.flat_map { |way| way.way_nodes.map(&:node_id) }
      end

      # - [0] in case some thing links to node 0 which doesn't exist. Shouldn't actually ever happen but it does. FIXME: file a ticket for this
      nodes_to_fetch = (list_of_way_nodes.uniq - node_ids) - [0]

      nodes += Node.includes(:node_tags).find(nodes_to_fetch) unless nodes_to_fetch.empty?

      @nodes = nodes.filter(&:visible?)

      @ways = ways.filter(&:visible?)

      @relations = Relation.nodes(@nodes).visible +
                   Relation.ways(@ways).visible

      # we do not normally return the "other" partners referenced by an relation,
      # e.g. if we return a way A that is referenced by relation X, and there's
      # another way B also referenced, that is not returned. But we do make
      # an exception for cases where an relation references another *relation*;
      # in that case we return that as well (but we don't go recursive here)
      @relations += Relation.relations(@relations.collect(&:id)).visible

      # this "uniq" may be slightly inefficient; it may be better to first collect and output
      # all node-related relations, then find the *not yet covered* way-related ones etc.
      @relations.uniq!

      response.headers["Content-Disposition"] = "attachment; filename=\"map.osm\""
      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end
  end
end
