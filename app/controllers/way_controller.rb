class WayController < ApplicationController
  require 'xml/libxml'

  session :off
  before_filter :authorize, :only => [:create, :update, :delete]
  before_filter :check_write_availability, :only => [:create, :update, :delete]
  before_filter :check_read_availability, :except => [:create, :update, :delete]
  after_filter :compress_output

  def create
    if request.put?
      way = Way.from_xml(request.raw_post, true)

      if way
        if !way.preconditions_ok?
          render :text => "", :status => :precondition_failed
        else
          way.user_id = @user.id
          way.save_with_history!

          render :text => way.id.to_s, :content_type => "text/plain"
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
      way = Way.find(params[:id])

      if way.visible
        render :text => way.to_xml.to_s, :content_type => "text/xml"
      else
        render :text => "", :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end

  def update
    begin
      way = Way.find(params[:id])

      if way.visible
        new_way = Way.from_xml(request.raw_post)

        if new_way and new_way.id == way.id
          if !new_way.preconditions_ok?
            render :text => "", :status => :precondition_failed
          else
            way.user_id = @user.id
            way.tags = new_way.tags
            way.nds = new_way.nds
            way.visible = true
            way.save_with_history!

            render :nothing => true
          end
        else
          render :nothing => true, :status => :bad_request
        end
      else
        render :text => "", :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end

  def delete
    begin
      way = Way.find(params[:id])

      if way.visible
        if RelationMember.find(:first, :joins => "INNER JOIN current_relations ON current_relations.id=current_relation_members.id", :conditions => [ "visible = 1 AND member_type='way' and member_id=?", params[:id]])
          render :text => "", :status => :precondition_failed
        else
          way.user_id = @user.id
          way.tags = []
          way.nds = []
          way.visible = false
	  way.save_with_history!

	  render :nothing => true
        end
      else
        render :text => "", :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue => ex
      puts ex
    end
  end

  def full
    begin
      way = Way.find(params[:id])

      if way.visible
        nd_ids = way.nds + [-1]
        nodes = Node.find(:all, :conditions => "visible = 1 AND id IN (#{nd_ids.join(',')})")

        # Render
        doc = OSM::API.new.get_xml_doc
        nodes.each do |node|
          doc.root << node.to_xml_node()
        end
        doc.root << way.to_xml_node()

        render :text => doc.to_s, :content_type => "text/xml"
      else
        render :text => "", :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end

  def ways
    begin
      ids = params['ways'].split(',').collect { |w| w.to_i }
    rescue
      ids = []
    end

    if ids.length > 0
      doc = OSM::API.new.get_xml_doc

      Way.find(ids).each do |way|
        doc.root << way.to_xml_node
      end

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :bad_request
    end
  end

  def ways_for_node
    wayids = WayNode.find(:all, :conditions => ['node_id = ?', params[:id]]).collect { |ws| ws.id }.uniq

    if wayids.length > 0
      doc = OSM::API.new.get_xml_doc

      Way.find(wayids).each do |way|
        doc.root << way.to_xml_node
      end

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :bad_request
    end
  end
end
