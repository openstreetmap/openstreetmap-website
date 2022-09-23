# The NodeController is the RESTful interface to Node objects

module Api
  class NodesController < ApiController
    require "xml/libxml"

    before_action :check_api_writable, :only => [:create, :update, :delete]
    before_action :check_api_readable, :except => [:create, :update, :delete]
    before_action :authorize, :only => [:create, :update, :delete]

    authorize_resource

    before_action :require_public_data, :only => [:create, :update, :delete]
    around_action :api_call_handle_error, :api_call_timeout

    before_action :set_request_formats, :except => [:create, :update, :delete]

    # Create a node from XML.
    def create
      assert_method :put

      node = Node.from_xml(request.raw_post, :create => true)

      # Assume that Node.from_xml has thrown an exception if there is an error parsing the xml
      node.create_with_history current_user
      render :plain => node.id.to_s
    end

    # Dump the details on a node given in params[:id]
    def show
      @node = Node.find(params[:id])

      response.last_modified = @node.timestamp

      if @node.visible
        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      else
        head :gone
      end
    end

    # Update a node from given XML
    def update
      node = Node.find(params[:id])
      new_node = Node.from_xml(request.raw_post)

      raise OSM::APIBadUserInput, "The id in the url (#{node.id}) is not the same as provided in the xml (#{new_node.id})" unless new_node && new_node.id == node.id

      node.update_from(new_node, current_user)
      render :plain => node.version.to_s
    end

    # Delete a node. Doesn't actually delete it, but retains its history
    # in a wiki-like way. We therefore treat it like an update, so the delete
    # method returns the new version number.
    def delete
      node = Node.find(params[:id])
      new_node = Node.from_xml(request.raw_post)

      raise OSM::APIBadUserInput, "The id in the url (#{node.id}) is not the same as provided in the xml (#{new_node.id})" unless new_node && new_node.id == node.id

      node.delete_with_history!(new_node, current_user)
      render :plain => node.version.to_s
    end

    # Dump the details on many nodes whose ids and optionally verions are given in the "nodes" parameter.
    def index
      raise OSM::APIBadUserInput, "The parameter nodes is required, and must be of the form nodes=ID[vVER][,ID[vVER][,ID[vVER]...]]" unless params["nodes"]

      id_ver_strings, id_strings = params["nodes"].split(",").partition { |iv| iv.include? "v" }
      id_vers = id_ver_strings.map { |iv| iv.split("v", 2).map(&:to_i) }
      ids = id_strings.map(&:to_i)

      raise OSM::APIBadUserInput, "No nodes were given to search for" if ids.empty?

      @nodes = Node.find(ids)
      @nodes += OldNode.find(id_vers) unless id_vers.empty?

      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end
  end
end
