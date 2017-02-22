class RelationController < ApplicationController
  require "xml/libxml"

  skip_before_action :verify_authenticity_token
  before_action :authorize, :only => [:create, :update, :delete]
  before_action :require_allow_write_api, :only => [:create, :update, :delete]
  before_action :require_public_data, :only => [:create, :update, :delete]
  before_action :check_api_writable, :only => [:create, :update, :delete]
  before_action :check_api_readable, :except => [:create, :update, :delete]
  around_action :api_call_handle_error, :api_call_timeout

  def create
    assert_method :put

    relation = Relation.from_xml(request.raw_post, true)

    # Assume that Relation.from_xml has thrown an exception if there is an error parsing the xml
    relation.create_with_history @user
    render :text => relation.id.to_s, :content_type => "text/plain"
  end

  def read
    relation = Relation.find(params[:id])
    response.last_modified = relation.timestamp
    if relation.visible
      render :text => relation.to_xml.to_s, :content_type => "text/xml"
    else
      render :text => "", :status => :gone
    end
  end

  def update
    logger.debug request.raw_post

    relation = Relation.find(params[:id])
    new_relation = Relation.from_xml(request.raw_post)

    unless new_relation && new_relation.id == relation.id
      raise OSM::APIBadUserInput.new("The id in the url (#{relation.id}) is not the same as provided in the xml (#{new_relation.id})")
    end

    relation.update_from new_relation, @user
    render :text => relation.version.to_s, :content_type => "text/plain"
  end

  def delete
    relation = Relation.find(params[:id])
    new_relation = Relation.from_xml(request.raw_post)
    if new_relation && new_relation.id == relation.id
      relation.delete_with_history!(new_relation, @user)
      render :text => relation.version.to_s, :content_type => "text/plain"
    else
      render :text => "", :status => :bad_request
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

      # create XML.
      doc = OSM::API.new.get_xml_doc

      visible_nodes = {}
      visible_members = { "Node" => {}, "Way" => {}, "Relation" => {} }
      changeset_cache = {}
      user_display_name_cache = {}

      nodes.each do |node|
        if (!node.visible?)
          node = node.last_visible_version
        end

        doc.root << node.to_xml_node(changeset_cache, user_display_name_cache)
        visible_nodes[node.id] = node
        visible_members["Node"][node.id] = true
      end

      ways.each do |way|
        next unless way.visible? # should be unnecessary if data is consistent.

        doc.root << way.to_xml_node(visible_nodes, changeset_cache, user_display_name_cache)
        visible_members["Way"][way.id] = true
      end

      relations.each do |rel|
        next unless rel.visible? # should be unnecessary if data is consistent.

        doc.root << rel.to_xml_node(nil, changeset_cache, user_display_name_cache)
        visible_members["Relation"][rel.id] = true
      end

      # finally add self and output
      doc.root << relation.to_xml_node(visible_members, changeset_cache, user_display_name_cache)
      render :text => doc.to_s, :content_type => "text/xml"

    else
      render :text => "", :status => :gone
    end
  end

  # -----------------------------------------------------------------
  # fordisplay
  #
  # input parameters: id
  #
  # returns XML representation of one relation object plus all its
  # members, plus all nodes part of member ways. If relation is 
  # deleted, attempts to use last-known-good version.
  # -----------------------------------------------------------------
  def fordisplay
    relation = Relation.find(params[:id])

    if relation.visible
      return full
    end

    relation = relation.latest_visible_version;
    
    if relation
  
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
        if (way.visible)
           way.way_nodes.collect(&:node_id)
        else
           lvv = way.latest_visible_version()
           if lvv
             lvv.way_nodes.collect(&:node_id)
           end
        end
      end
      node_ids += way_node_ids.flatten
      nodes = Node.where(:id => node_ids.uniq).includes(:node_tags)
  
      # create XML.
      doc = OSM::API.new.get_xml_doc
      doc.root["deleted"] = "true"

      visible_nodes = {}
      changeset_cache = {}
      user_display_name_cache = {}
  
      nodes.each do |node|
        if node.visible?
           doc.root << node.to_xml_node(changeset_cache, user_display_name_cache)
        else
           lvv = node.latest_visible_version()
           if lvv
             doc.root << lvv.to_xml_node(changeset_cache, user_display_name_cache)
           end
        end
        visible_nodes[node.id] = node
      end
  
      ways.each do |way|
        if way.visible?
          doc.root << way.to_xml_node(visible_nodes, changeset_cache, user_display_name_cache)
        else
          lvv = way.latest_visible_version()
          if lvv
            doc.root << lvv.to_xml_node(changeset_cache, user_display_name_cache)
          end
        end
      end
  
      relations.each do |rel|
        if rel.visible?
          doc.root << rel.to_xml_node(nil, changeset_cache, user_display_name_cache)
        else
          lvv = rel.latest_visible_version()
          if lvv
            doc.root << lvv.to_xml_node(changeset_cache, user_display_name_cache)
          end
        end
      end
  
      # finally add self and output
      doc.root << relation.to_xml_node(changeset_cache, user_display_name_cache)
      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :text => "", :status => :gone
    end 

  end

  def relations
    unless params["relations"]
      raise OSM::APIBadUserInput.new("The parameter relations is required, and must be of the form relations=id[,id[,id...]]")
    end

    ids = params["relations"].split(",").collect(&:to_i)

    if ids.empty?
      raise OSM::APIBadUserInput.new("No relations were given to search for")
    end

    doc = OSM::API.new.get_xml_doc

    Relation.find(ids).each do |relation|
      doc.root << relation.to_xml_node
    end

    render :text => doc.to_s, :content_type => "text/xml"
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

  def relations_for_object(objtype)
    relationids = RelationMember.where(:member_type => objtype, :member_id => params[:id]).collect(&:relation_id).uniq

    doc = OSM::API.new.get_xml_doc

    Relation.find(relationids).each do |relation|
      doc.root << relation.to_xml_node if relation.visible
    end

    render :text => doc.to_s, :content_type => "text/xml"
  end
end
