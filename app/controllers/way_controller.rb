class WayController < ApplicationController
  require 'xml/libxml'

  before_filter :authorize

  def create
    if request.put?
      way = Way.from_xml(request.raw_post, true)

      if way
        way.user_id = @user.id
        if way.save_with_history
          render :text => way.id
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
    unless Way.exists?(params[:id])
      render :nothing => true, :status => 404
      return
    end

    way = Way.find(params[:id])
    case request.method
   
    when :get
      unless way.visible
        render :nothing => true, :status => 410
        return
      end
      render :text => way.to_xml.to_s

    when :delete
      unless way.visible
        render :nothing => true, :status => 410
        return
      end

      way.visible = false
      way.save_with_history

    end
  end
end
