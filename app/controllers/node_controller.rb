# The NodeController is the RESTful interface to Node objects

class NodeController < ApplicationController
  require 'xml/libxml'

  session :off
  before_filter :authorize, :only => [:create, :update, :delete]
  before_filter :require_public_data, :only => [:create, :update, :delete]
  before_filter :check_api_writable, :only => [:create, :update, :delete]
  before_filter :check_api_readable, :except => [:create, :update, :delete]
  after_filter :compress_output
  around_filter :api_call_handle_error

  # Create a node from XML.
  def create
    assert_method :put

    node = Node.from_xml(request.raw_post, true)

    if node
      node.create_with_history @user
      render :text => node.id.to_s, :content_type => "text/plain"
    else
      raise OSM::APIBadXMLError.new(:node, request.raw_post)
    end
  end

  # Dump the details on a node given in params[:id]
  def read
    node = Node.find(params[:id])
    if node.visible?
      response.headers['Last-Modified'] = node.timestamp.rfc822
      render :text => node.to_xml.to_s, :content_type => "text/xml"
    else
      render :text => "", :status => :gone
    end
  end
  
  # Update a node from given XML
  def update
    node = Node.find(params[:id])
    new_node = Node.from_xml(request.raw_post)
    
    if new_node and new_node.id == node.id
      node.update_from(new_node, @user)
      render :text => node.version.to_s, :content_type => "text/plain"
    else
      render :nothing => true, :status => :bad_request
    end
  end

  # Delete a node. Doesn't actually delete it, but retains its history 
  # in a wiki-like way. We therefore treat it like an update, so the delete
  # method returns the new version number.
  def delete
    node = Node.find(params[:id])
    new_node = Node.from_xml(request.raw_post)
    
    if new_node and new_node.id == node.id
      node.delete_with_history!(new_node, @user)
      render :text => node.version.to_s, :content_type => "text/plain"
    else
      render :nothing => true, :status => :bad_request
    end
  end

  # Dump the details on many nodes whose ids are given in the "nodes" parameter.
  def nodes
    ids = params['nodes'].split(',').collect { |n| n.to_i }

    if ids.length > 0
      doc = OSM::API.new.get_xml_doc

      Node.find(ids).each do |node|
        doc.root << node.to_xml_node
      end 

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :bad_request
    end
  end
end
