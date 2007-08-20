class WayController < ApplicationController
  require 'xml/libxml'

  session :off
  before_filter :authorize, :only => [:create, :update, :delete]
  before_filter :check_availability, :only => [:create, :update, :delete]
  after_filter :compress_output

  def create
    if request.put?
      way = Way.from_xml(request.raw_post, true)

      if way
        if !way.preconditions_ok?
          render :nothing => true, :status => :precondition_failed
        else
          way.user_id = @user.id

          if way.save_with_history
            render :text => way.id.to_s, :content_type => "text/plain"
          else
            render :nothing => true, :status => :internal_server_error
          end
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
      way = Way.find(params[:id])

      if way.visible
        new_way = Way.from_xml(request.raw_post)

        if new_way and new_way.id == way.id
          if !new_way.preconditions_ok?
            render :nothing => true, :status => :precondition_failed
          else
            way.user_id = @user.id
            way.tags = new_way.tags
            way.segs = new_way.segs
            way.visible = true

            if way.save_with_history
              render :nothing => true
            else
              render :nothing => true, :status => :internal_server_error
            end
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
      way = Way.find(params[:id])

      if way.visible
        way.user_id = @user.id
        way.tags = []
        way.segs = []
        way.visible = false

        if way.save_with_history
          render :nothing => true
        else
          render :nothing => true, :status => :internal_server_error
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

  def full
    begin
      way = Way.find(params[:id])

      if way.visible
        # In future, we might want to do all the data fetch in one step
        seg_ids = way.segs + [-1]
        segments = Segment.find_by_sql "select * from current_segments where visible = 1 and id IN (#{seg_ids.join(',')})"

        node_ids = segments.collect {|segment| segment.node_a }
        node_ids += segments.collect {|segment| segment.node_b }
        node_ids += [-1]
        nodes = Node.find(:all, :conditions => "visible = 1 AND id IN (#{node_ids.join(',')})")

        # Render
        doc = OSM::API.new.get_xml_doc
        nodes.each do |node|
          doc.root << node.to_xml_node()
        end
        segments.each do |segment|
          doc.root << segment.to_xml_node()
        end
        doc.root << way.to_xml_node()

        render :text => doc.to_s, :content_type => "text/xml"
      else
        render :nothing => true, :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
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

  def ways_for_segment
    wayids = WaySegment.find(:all, :conditions => ['segment_id = ?', params[:id]]).collect { |ws| ws.id }.uniq

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
