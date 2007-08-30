class NodeController < ApplicationController
  require 'xml/libxml'

  session :off
  before_filter :authorize, :only => [:create, :update, :delete]
  before_filter :check_availability, :only => [:create, :update, :delete]
  after_filter :compress_output

  def create
    if request.put?
      node = Node.from_xml(request.raw_post, true)

      if node
        node.user_id = @user.id
        node.visible = true

        if node.save_with_history
          render :text => node.id.to_s, :content_type => "text/plain"
        else
          render :nothing => true, :status => :internal_server_error
        end
      else
        render :nothing => true, :status => :bad_request
      end
    else
      render :nothing => true, :status => :method_not_allowed
    end
  end

  def read
    begin
      node = Node.find(params[:id])

      if node.visible
        render :text => node.to_xml.to_s, :content_type => "text/xml"
       else
        render :nothing => true, :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end

  def update
    begin
      node = Node.find(params[:id])

      if node.visible
        new_node = Node.from_xml(request.raw_post)

        if new_node and new_node.id == node.id
          node.user_id = @user.id
          node.latitude = new_node.latitude 
          node.longitude = new_node.longitude
          node.tags = new_node.tags

          if node.save_with_history
            render :nothing => true
          else
            render :nothing => true, :status => :internal_server_error
          end
        else
          render :nothing => true, :status => :bad_request
        end
      else
        render :nothing => true, :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end

  def delete
    begin
      node = Node.find(params[:id])

      if node.visible
        if WayNode.find(:first, :joins => "INNER JOIN current_ways ON current_ways.id = current_way_nodes.id", :conditions => [ "current_ways.visible = 1 AND current_way_nodes.node_id = ?", node.id ])
          render :nothing => true, :status => :precondition_failed
        elsif RelationMember.find(:first, :joins => "INNER JOIN current_relations ON current_relations.id=current_relation_members.id", :conditions => [ "visible = 1 AND member_type='node' and member_id=?", params[:id]])
          render :nothing => true, :status => :precondition_failed
        else
          node.user_id = @user.id
          node.visible = 0
          node.save_with_history
          render :nothing => true
        end
      else
        render :nothing => true, :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end

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
