class SegmentController < ApplicationController
  require 'xml/libxml'

  before_filter :authorize

  def create
    if request.put?
      segment = Segment.from_xml(request.raw_post, true)

      if segment
        
        segment.user_id = @user.id

        a = Node.find(segment.node_a.to_i)
        b = Node.find(segment.node_b.to_i)
        
        unless a and a.visible and b and b.visible  
          render :nothing => true, :status => 400
        end

        if segment.save_with_history
          render :text => segment.id
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

  def history
    segment = Segment.find(params[:id])

    unless segment
      render :nothing => true, :staus => 404
      return
    end

    doc = XML::Document.new
    doc.encoding = 'UTF-8' 
    root = XML::Node.new 'osm'
    root['version'] = '0.4'
    root['generator'] = 'OpenStreetMap server'
    doc.root = root

    segment.old_segments.each do |old_segment|
      el1 = XML::Node.new 'segment'
      el1['id'] = old_segment.id.to_s
      el1['from'] = old_segment.node_a.to_s
      el1['to'] = old_segment.node_b.to_s
      Segment.split_tags(el1, old_segment.tags)
      el1['visible'] = old_segment.visible.to_s
      el1['timestamp'] = old_segment.timestamp.xmlschema
      root << el1
    end

    render :text => doc.to_s
  end


end
