class SegmentController < ApplicationController
  require 'xml/libxml'

  session :off
  before_filter :authorize, :only => [:create, :update, :delete]
  before_filter :check_availability, :only => [:create, :update, :delete]
  after_filter :compress_output

  def create
    if request.put?
      segment = Segment.from_xml(request.raw_post, true)

      if segment
        if segment.node_a == segment.node_b
          render :nothing => true, :status => :expectation_failed
        elsif !segment.preconditions_ok?
          render :nothing => true, :status => :precondition_failed
        else
          segment.user_id = @user.id
          segment.from_node = Node.find(segment.node_a.to_i)
          segment.to_node = Node.find(segment.node_b.to_i)

          if segment.save_with_history
            render :text => segment.id.to_s, :content_type => "text/plain"
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
      segment = Segment.find(params[:id])

      if segment.visible
        render :text => segment.to_xml.to_s, :content_type => "text/xml"
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
      segment = Segment.find(params[:id])

      if segment.visible
        new_segment = Segment.from_xml(request.raw_post)

        if new_segment and new_segment.id == segment.id
          if new_segment.node_a == new_segment.node_b
            render :nothing => true, :status => :expectation_failed
          elsif !new_segment.preconditions_ok?
            render :nothing => true, :status => :precondition_failed
          else
            segment.user_id = @user.id
            segment.node_a = new_segment.node_a
            segment.node_b = new_segment.node_b
            segment.tags = new_segment.tags
            segment.visible = new_segment.visible

            if segment.save_with_history
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
      segment = Segment.find(params[:id])

      if segment.visible
        if WaySegment.find(:first, :joins => "INNER JOIN current_ways ON current_ways.id = current_way_segments.id", :conditions => [ "current_ways.visible = 1 AND current_way_segments.segment_id = ?", segment.id ])
          render :nothing => true, :status => :precondition_failed
        else
          segment.user_id = @user.id
          segment.visible = 0

          if segment.save_with_history
            render :nothing => true
          else
            render :nothing => true, :status => :internal_server_error
          end
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

  def segments
    ids = params['segments'].split(',').collect { |s| s.to_i }

    if ids.length > 0
      doc = OSM::API.new.get_xml_doc

      Segment.find(ids).each do |segment|
        doc.root << segment.to_xml_node
      end 

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :bad_request
    end
  end

  def segments_for_node
    segmentids = Segment.find(:all, :conditions => ['node_a = ? OR node_b = ?', params[:id], params[:id]]).collect { |s| s.id }.uniq

    if segmentids.length > 0
      doc = OSM::API.new.get_xml_doc

      Segment.find(segmentids).each do |segment|
        doc.root << segment.to_xml_node
      end

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :bad_request
    end
  end
end
