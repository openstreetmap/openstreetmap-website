# The NodeController is the RESTful interface to Node objects

class NodeController < ApplicationController
  require 'xml/libxml'

  session :off
  before_filter :authorize, :only => [:create, :update, :delete]
  before_filter :check_write_availability, :only => [:create, :update, :delete]
  before_filter :check_read_availability, :except => [:create, :update, :delete]
  after_filter :compress_output

  # Create a node from XML.
  def create
    if request.put?
      node = Node.from_xml(request.raw_post, true)

      if node
        node.user_id = @user.id
        node.visible = true
        node.save_with_history!

        render :text => node.id.to_s, :content_type => "text/plain"
      else
        render :nothing => true, :status => :bad_request
      end
    else
      render :nothing => true, :status => :method_not_allowed
    end
  end

  # Dump the details on a node given in params[:id]
  def read
    begin
      node = Node.find(params[:id])
      if node.visible
        response.headers['Last-Modified'] = node.timestamp.rfc822
        render :text => node.to_xml.to_s, :content_type => "text/xml"
       else
        render :text => "", :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end

  # Update a node from given XML
  def update
    begin
      node = Node.find(params[:id])
      new_node = Node.from_xml(request.raw_post)

      if new_node and new_node.id == node.id
        node.user_id = @user.id
        node.latitude = new_node.latitude 
        node.longitude = new_node.longitude
        node.tags = new_node.tags
        node.visible = true
        node.save_with_history!

        render :nothing => true
      else
        render :nothing => true, :status => :bad_request
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end

  # Delete a node. Doesn't actually delete it, but retains its history in a wiki-like way.
  # FIXME remove all the fricking SQL
  def delete
    begin
      node = Node.find(params[:id])

      if node.visible
        if WayNode.find(:first, :joins => "INNER JOIN current_ways ON current_ways.id = current_way_nodes.id", :conditions => [ "current_ways.visible = 1 AND current_way_nodes.node_id = ?", node.id ])
          render :text => "", :status => :precondition_failed
        elsif RelationMember.find(:first, :joins => "INNER JOIN current_relations ON current_relations.id=current_relation_members.id", :conditions => [ "visible = 1 AND member_type='node' and member_id=?", params[:id]])
          render :text => "", :status => :precondition_failed
        else
          node.user_id = @user.id
          node.visible = 0
          node.save_with_history!

          render :nothing => true
        end
      else
        render :text => "", :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end

  # WTF does this do?
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
