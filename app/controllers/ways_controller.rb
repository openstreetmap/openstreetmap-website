class WaysController < ApplicationController
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

    way = Way.from_xml(request.raw_post, true)

    # Assume that Way.from_xml has thrown an exception if there is an error parsing the xml
    way.create_with_history current_user
    render :plain => way.id.to_s
  end

  def read
    way = Way.find(params[:id])

    response.last_modified = way.timestamp

    if way.visible
      render :xml => way.to_xml.to_s
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
    way = Way.includes(:nodes => :node_tags).find(params[:id])

    if way.visible
      visible_nodes = {}
      changeset_cache = {}
      user_display_name_cache = {}

      doc = OSM::API.new.get_xml_doc
      way.nodes.uniq.each do |node|
        if node.visible
          doc.root << node.to_xml_node(changeset_cache, user_display_name_cache)
          visible_nodes[node.id] = node
        end
      end
      doc.root << way.to_xml_node(visible_nodes, changeset_cache, user_display_name_cache)

      render :xml => doc.to_s
    else
      head :gone
    end
  end

  def ways
    unless params["ways"]
      raise OSM::APIBadUserInput, "The parameter ways is required, and must be of the form ways=id[,id[,id...]]"
    end

    ids = params["ways"].split(",").collect(&:to_i)

    raise OSM::APIBadUserInput, "No ways were given to search for" if ids.empty?

    doc = OSM::API.new.get_xml_doc

    Way.find(ids).each do |way|
      doc.root << way.to_xml_node
    end

    render :xml => doc.to_s
  end

  ##
  # returns all the ways which are currently using the node given in the
  # :id parameter. note that this used to return deleted ways as well, but
  # this seemed not to be the expected behaviour, so it was removed.
  def ways_for_node
    wayids = WayNode.where(:node_id => params[:id]).collect { |ws| ws.id[0] }.uniq

    doc = OSM::API.new.get_xml_doc

    Way.find(wayids).each do |way|
      doc.root << way.to_xml_node if way.visible
    end

    render :xml => doc.to_s
  end
end
