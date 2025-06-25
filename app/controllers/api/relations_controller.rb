module Api
  class RelationsController < ApiController
    before_action :check_api_writable, :only => [:create, :update, :destroy]
    before_action :authorize, :only => [:create, :update, :destroy]

    authorize_resource

    before_action :require_public_data, :only => [:create, :update, :destroy]
    before_action :set_request_formats, :except => [:create, :update, :destroy]
    before_action :check_rate_limit, :only => [:create, :update, :destroy]

    def index
      raise OSM::APIBadUserInput, "The parameter relations is required, and must be of the form relations=id[,id[,id...]]" unless params["relations"]

      ids = params["relations"].split(",").collect(&:to_i)

      raise OSM::APIBadUserInput, "No relations were given to search for" if ids.empty?

      @relations = Relation.find(ids)

      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end

    def show
      relation = Relation.find(params[:id])

      response.last_modified = relation.timestamp unless params[:full]

      @nodes = []
      @ways = []
      @relations = []

      if relation.visible
        if params[:full]
          # with parameter :full
          # returns representation of one relation object plus all its
          # members, plus all nodes part of member ways

          # first find the ids of nodes, ways and relations referenced by this
          # relation - note that we exclude this relation just in case.

          node_ids = relation.members.select { |m| m[0] == "Node" }.pluck(1)
          way_ids = relation.members.select { |m| m[0] == "Way" }.pluck(1)
          relation_ids = relation.members.select { |m| m[0] == "Relation" && m[1] != relation.id }.pluck(1)

          # next load the relations and the ways.

          relations = Relation.where(:id => relation_ids).includes(:relation_tags)
          ways = Way.where(:id => way_ids).includes(:way_nodes, :way_tags)

          # now additionally collect nodes referenced by ways. Note how we
          # recursively evaluate ways but NOT relations.

          way_node_ids = ways.collect do |way|
            way.way_nodes.collect(&:node_id)
          end
          node_ids += way_node_ids.flatten
          nodes = Node.where(:id => node_ids.uniq).includes(:node_tags)

          @nodes = []
          nodes.each do |node|
            next unless node.visible? # should be unnecessary if data is consistent.

            @nodes << node
          end

          ways.each do |way|
            next unless way.visible? # should be unnecessary if data is consistent.

            @ways << way
          end

          relations.each do |rel|
            next unless rel.visible? # should be unnecessary if data is consistent.

            @relations << rel
          end
        end

        # finally add self
        @relations << relation

        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      else
        head :gone
      end
    end

    def create
      relation = Relation.from_xml(request.raw_post, :create => true)

      # Assume that Relation.from_xml has thrown an exception if there is an error parsing the xml
      relation.create_with_history current_user
      render :plain => relation.id.to_s
    end

    def update
      relation = Relation.find(params[:id])
      new_relation = Relation.from_xml(request.raw_post)

      raise OSM::APIBadUserInput, "The id in the url (#{relation.id}) is not the same as provided in the xml (#{new_relation.id})" unless new_relation && new_relation.id == relation.id

      relation.update_from new_relation, current_user
      render :plain => relation.version.to_s
    end

    def destroy
      relation = Relation.find(params[:id])
      new_relation = Relation.from_xml(request.raw_post)
      if new_relation && new_relation.id == relation.id
        relation.delete_with_history!(new_relation, current_user)
        render :plain => relation.version.to_s
      else
        head :bad_request
      end
    end
  end
end
