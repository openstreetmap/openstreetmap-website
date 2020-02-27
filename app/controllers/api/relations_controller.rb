module Api
  class RelationsController < ApiController
    require "xml/libxml"

    before_action :authorize, :only => [:create, :update, :delete]

    authorize_resource

    before_action :require_public_data, :only => [:create, :update, :delete]
    before_action :check_api_writable, :only => [:create, :update, :delete]
    before_action :check_api_readable, :except => [:create, :update, :delete]
    around_action :api_call_handle_error, :api_call_timeout

    before_action :set_default_request_format, :except => [:create, :update, :delete]

    def create
      assert_method :put

      relation = Relation.from_xml(request.raw_post, true)

      # Assume that Relation.from_xml has thrown an exception if there is an error parsing the xml
      relation.create_with_history current_user
      render :plain => relation.id.to_s
    end

    def show
      @relation = Relation.find(params[:id])
      response.last_modified = @relation.timestamp
      if @relation.visible
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
      logger.debug request.raw_post

      relation = Relation.find(params[:id])
      new_relation = Relation.from_xml(request.raw_post)

      raise OSM::APIBadUserInput, "The id in the url (#{relation.id}) is not the same as provided in the xml (#{new_relation.id})" unless new_relation && new_relation.id == relation.id

      relation.update_from new_relation, current_user
      render :plain => relation.version.to_s
    end

    def delete
      relation = Relation.find(params[:id])
      new_relation = Relation.from_xml(request.raw_post)
      if new_relation && new_relation.id == relation.id
        relation.delete_with_history!(new_relation, current_user)
        render :plain => relation.version.to_s
      else
        head :bad_request
      end
    end

    # -----------------------------------------------------------------
    # full
    #
    # input parameters: id
    #
    # returns XML representation of one relation object plus all its
    # members, plus all nodes part of member ways
    # -----------------------------------------------------------------
    def full
      relation = Relation.find(params[:id])

      if relation.visible

        # first find the ids of nodes, ways and relations referenced by this
        # relation - note that we exclude this relation just in case.

        node_ids = relation.members.select { |m| m[0] == "Node" }.map { |m| m[1] }
        way_ids = relation.members.select { |m| m[0] == "Way" }.map { |m| m[1] }
        relation_ids = relation.members.select { |m| m[0] == "Relation" && m[1] != relation.id }.map { |m| m[1] }

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

        visible_nodes = {}

        @nodes = []
        nodes.each do |node|
          next unless node.visible? # should be unnecessary if data is consistent.

          @nodes << node
          visible_nodes[node.id] = node
        end

        @ways = []
        ways.each do |way|
          next unless way.visible? # should be unnecessary if data is consistent.

          @ways << way
        end

        @relations = []
        relations.each do |rel|
          next unless rel.visible? # should be unnecessary if data is consistent.

          @relations << rel
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

    def relations_for_way
      relations_for_object("Way")
    end

    def relations_for_node
      relations_for_object("Node")
    end

    def relations_for_relation
      relations_for_object("Relation")
    end

    private

    def relations_for_object(objtype)
      relationids = RelationMember.where(:member_type => objtype, :member_id => params[:id]).collect(&:relation_id).uniq

      @relations = []

      Relation.find(relationids).each do |relation|
        @relations << relation if relation.visible
      end

      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end
  end
end
