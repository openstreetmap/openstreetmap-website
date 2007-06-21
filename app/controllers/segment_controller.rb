class SegmentController < ApplicationController
  require 'xml/libxml'

  before_filter :authorize
  after_filter :compress_output

  def create
    response.headers["Content-Type"] = 'text/xml'
    if request.put?
      segment = Segment.from_xml(request.raw_post, true)

      if segment
        segment.user_id = @user.id

        segment.from_node = Node.find(segment.node_a.to_i)
        segment.to_node = Node.find(segment.node_b.to_i)
          
        if segment.from_node == segment.to_node
          render :nothing => true, :status => HTTP_EXPECTATION_FAILED
          return
        end
        
        unless segment.preconditions_ok? # are the nodes visible?
          render :nothing => true, :status => HTTP_PRECONDITION_FAILED
          return
        end

        if segment.save_with_history
          render :text => segment.id.to_s
        else
          render :nothing => true, :status => 500
        end
        return
      else
        render :nothing => true, :status => 400 # if we got here the doc didnt parse
        return
      end
    end

    render :nothing => true, :status => 500 # something went very wrong
  end

  def rest
    response.headers["Content-Type"] = 'text/xml'
    unless Segment.exists?(params[:id])
      render :nothing => true, :status => 404
      return
    end

    segment = Segment.find(params[:id])

    case request.method

    when :get
      render :text => segment.to_xml.to_s
      return

    when :delete
      if segment.visible
        if WaySegment.find(:first, :joins => "INNER JOIN current_ways ON current_ways.id = current_way_segments.id", :conditions => [ "current_ways.visible = 1 AND current_way_segments.segment_id = ?", segment.id ])
          render :nothing => true, :status => HTTP_PRECONDITION_FAILED
        else
          segment.visible = 0
          segment.save_with_history
          render :nothing => true
        end
      else
        render :nothing => true, :status => 410
      end

    when :put
      new_segment = Segment.from_xml(request.raw_post)

      if new_segment
        if new_segment.node_a == new_segment.node_b
          render :nothing => true, :status => HTTP_EXPECTATION_FAILED
          return
        end
        
        unless new_segment.preconditions_ok? # are the nodes visible?
          render :nothing => true, :status => HTTP_PRECONDITION_FAILED
          return
        end

        segment.timestamp = Time.now
        segment.user_id = @user.id
        segment.node_a = new_segment.node_a
        segment.node_b = new_segment.node_b
        segment.tags = new_segment.tags
        segment.visible = new_segment.visible

        if segment.id == new_segment.id and segment.save_with_history
          render :nothing => true
        else
          render :nothing => true, :status => 500
        end
      else
        render :nothing => true, :status => 400 # if we got here the doc didnt parse
      end
    end

  end

  def segments
    response.headers["Content-Type"] = 'text/xml'
    ids = params['segments'].split(',').collect {|s| s.to_i }
    if ids.length > 0
      segmentlist = Segment.find(ids)
      doc = OSM::API.new.get_xml_doc
      segmentlist.each do |segment|
        doc.root << segment.to_xml_node
      end 
      render :text => doc.to_s
    else
      render :nothing => true, :status => 400
    end
  end

  def segments_for_node
    response.headers["Content-Type"] = 'text/xml'
    segmentids = Segment.find(:all, :conditions => ['node_a = ? OR node_b = ?', params[:id], params[:id]]).collect { |s| s.id }.uniq
    if segmentids.length > 0
      segmentlist = Segment.find(segmentids)
      doc = OSM::API.new.get_xml_doc
      segmentlist.each do |segment|
        doc.root << segment.to_xml_node
      end 
      render :text => doc.to_s
    else
      render :nothing => true, :status => 400
    end
  end

end
