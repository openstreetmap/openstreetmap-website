class SegmentController < ApplicationController

  require 'xml/libxml'

  before_filter :authorize

  def create
    if request.put?
      segment = Segment.from_xml(request.raw_post, true)

      if segment
        segment.user_id = @user.id
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
      render :nothing => true, :status => 400
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

      segment.latitude = new_segment.latitude 
      segment.longitude = new_segment.longitude
      segment.tags = new_segment.tags

      if segment.id == new_segment.id and segment.save_with_history
        render :nothing => true, :status => 200
      else
        render :nothing => true, :status => 500
      end
      return
    end

  end


end
