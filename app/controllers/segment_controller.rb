class SegmentController < ApplicationController
  require 'xml/libxml'

  before_filter :authorize
  after_filter :compress_output

  def create
    response.headers["Content-Type"] = 'application/xml'
    if request.put?
      segment = Segment.from_xml(request.raw_post, true)

      if segment
        segment.user_id = @user.id

        segment.from_node = Node.find(segment.node_a.to_i)
        segment.to_node = Node.find(segment.node_b.to_i)
        
        unless segment.preconditions_ok? # are the nodes visible?
          render :nothing => true, :status => 412
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
    response.headers["Content-Type"] = 'application/xml'
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
        segment.visible = 0
        segment.save_with_history
        render :nothing => true
      else
        render :nothing => true, :status => 410
      end

    when :put
      new_segment = Segment.from_xml(request.raw_post)

      segment.timestamp = Time.now
      segment.user_id = @user.id

      segment.node_a = new_segment.node_a
      segment.node_b = new_segment.node_b
      segment.tags = new_segment.tags
      segment.visible = new_segment.visible

      if segment.id == new_segment.id and segment.save_with_history
        render :nothing => true, :status => 200
      else
        render :nothing => true, :status => 500
      end
      return
    end

  end

  def segments
    response.headers["Content-Type"] = 'application/xml'
    ids = params['segments'].split(',').collect {|s| s.to_i }
    if ids.length > 0
      segmentlist = Segment.find(ids)
      doc = OSM::API.get_xml_doc
      segmentlist.each do |segment|
        doc.root << segment.to_xml_node
      end 
      render :text => doc.to_s
    else
      render :nothing => true, :status => 400
    end
  end

end
