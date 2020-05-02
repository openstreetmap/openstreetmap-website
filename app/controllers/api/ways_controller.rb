module Api
  class WaysController < ApiController
    require "xml/libxml"

    before_action :authorize, :only => [:create, :update, :delete]

    authorize_resource

    before_action :require_public_data, :only => [:create, :update, :delete]
    before_action :check_api_writable, :only => [:create, :update, :delete]
    before_action :check_api_readable, :except => [:create, :update, :delete]
    around_action :api_call_handle_error, :api_call_timeout

    before_action :set_request_formats, :except => [:create, :update, :delete]

    def create
      assert_method :put

      way = Way.from_xml(request.raw_post, true)

      # Assume that Way.from_xml has thrown an exception if there is an error parsing the xml
      way.create_with_history current_user
      render :plain => way.id.to_s
    end

    def show
      @way = Way.find(params[:id])

      response.last_modified = @way.timestamp

      if @way.visible
        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      else
        head :gone
      end
    end

    def update
      way = Way.find(params[:id])
      new_way = Way.from_xml(request.raw_post)

      unless new_way && new_way.id == way.id
        raise OSM::APIBadUserInput, "The id in the url (#{way.id}) is not the same as provided in the xml (#{new_way.id})"
      end

      way.update_from(new_way, current_user)
      render :plain => way.version.to_s
    end

    # This is the API call to delete a way
    def delete
      way = Way.find(params[:id])
      new_way = Way.from_xml(request.raw_post)

      if new_way && new_way.id == way.id
        way.delete_with_history!(new_way, current_user)
        render :plain => way.version.to_s
      else
        head :bad_request
      end
    end

    def full
      @way = Way.includes(:nodes => :node_tags).find(params[:id])

      if @way.visible
        visible_nodes = {}

        @nodes = []

        @way.nodes.uniq.each do |node|
          if node.visible
            @nodes << node
            visible_nodes[node.id] = node
          end
        end

        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      else
        head :gone
      end
    end

    def index
      unless params["ways"]
        raise OSM::APIBadUserInput, "The parameter ways is required, and must be of the form ways=id[,id[,id...]]"
      end

      ids = params["ways"].split(",").collect(&:to_i)

      raise OSM::APIBadUserInput, "No ways were given to search for" if ids.empty?

      @ways = Way.find(ids)

      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end

    ##
    # returns all the ways which are currently using the node given in the
    # :id parameter. note that this used to return deleted ways as well, but
    # this seemed not to be the expected behaviour, so it was removed.
    def ways_for_node
      wayids = WayNode.where(:node_id => params[:id]).collect { |ws| ws.id[0] }.uniq

      @ways = Way.where(:id => wayids, :visible => true)

      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end
  end
end
