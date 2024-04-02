module Api
  class WaysController < ElementsController
    before_action :check_api_writable, :only => [:create, :update, :destroy]
    before_action :authorize, :only => [:create, :update, :destroy]

    authorize_resource

    before_action :require_public_data, :only => [:create, :update, :destroy]
    before_action :set_request_formats, :except => [:create, :update, :destroy]
    before_action :check_rate_limit, :only => [:create, :update, :destroy]

    def index
      index_for_models(Way)
    end

    def show
      @way = Way
      @way = @way.includes(:nodes => :node_tags) if params[:full]
      @way = @way.find(params[:id])

      response.last_modified = @way.timestamp unless params[:full]

      if @way.visible
        if params[:full]
          @nodes = []

          @way.nodes.uniq.each do |node|
            @nodes << node if node.visible
          end
        end

        respond_to do |format|
          format.xml
          format.json
        end
      else
        head :gone
      end
    end

    def create
      way = Way.from_xml(request.raw_post, :create => true)

      # Assume that Way.from_xml has thrown an exception if there is an error parsing the xml
      way.create_with_history current_user
      render :plain => way.id.to_s
    end

    def update
      way = Way.find(params[:id])
      new_way = Way.from_xml(request.raw_post)

      raise OSM::APIBadUserInput, "The id in the url (#{way.id}) is not the same as provided in the xml (#{new_way.id})" unless new_way && new_way.id == way.id

      way.update_from(new_way, current_user)
      render :plain => way.version.to_s
    end

    # This is the API call to delete a way
    def destroy
      way = Way.find(params[:id])
      new_way = Way.from_xml(request.raw_post)

      if new_way && new_way.id == way.id
        way.delete_with_history!(new_way, current_user)
        render :plain => way.version.to_s
      else
        head :bad_request
      end
    end
  end
end
