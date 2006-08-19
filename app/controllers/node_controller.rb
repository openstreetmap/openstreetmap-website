class NodeController < ApplicationController
  require 'xml/libxml'

  before_filter :authorize

  def create
    if request.put?
      node = Node.from_xml(request.raw_post, true)

      if node
        node.user_id = @user.id
        if node.save_with_history

          render :text => node.id
        else
          render :text => 'truesrgtsrtfgsar', :status => 500
#          render :nothing => true, :status => 500
        end
        return

      else
        render :nothing => true, :status => 400 # if we got here the doc didnt parse
        return
      end
    end

          render :text => 'FFFFFFFFFF ', :status => 500
#    render :nothing => true, :status => 500 # something went very wrong
  end

  def rest
    unless Node.exists?(params[:id])
      render :nothing => true, :status => 400
      return
    end

    node = Node.find(params[:id])

    case request.method

    when :get
      render :text => node.to_xml.to_s
      return

    when :delete

      if node.visible
        node.visible = 0

        node.save_with_history

        render :nothing => true
      else
        render :nothing => true, :status => 410
      end

    when :put

      new_node = Node.from_xml(request.raw_post)

      new_node.timestamp = Time.now
      new_node.user_id = @user.id

      if node.id == new_node.id and new_node.save_with_history
        render :text => node.id
      else
        render :nothing => true, :status => 500
      end
      return
    end

  end


end
