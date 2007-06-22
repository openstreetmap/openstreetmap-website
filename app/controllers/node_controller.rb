class NodeController < ApplicationController
  require 'xml/libxml'

  before_filter :authorize
  after_filter :compress_output

  def create
    response.headers["Content-Type"] = 'text/xml'
    if request.put?
      node = Node.from_xml(request.raw_post, true)

      if node
        node.user_id = @user.id
        node.visible = 1
        if node.save_with_history
          render :text => node.id.to_s
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
    unless Node.exists?(params[:id])
      render :nothing => true, :status => 404
      return
    end

    node = Node.find(params[:id])

    case request.method

    when :get
      unless node
        render :nothing => true, :status => 500
        return
      end

      unless node.visible
        render :nothing => true, :status => 410
        return
      end

      render :text => node.to_xml.to_s
      return

    when :delete
      if node.visible
        if Segment.find(:first, :conditions => [ "visible = 1 and (node_a = ? or node_b = ?)", node.id, node.id])
          render :nothing => true, :status => HTTP_PRECONDITION_FAILED
        else
          node.user_id = @user.id
          node.visible = 0
          node.save_with_history
          render :nothing => true
        end
      else
        render :nothing => true, :status => 410
      end

    when :put
      new_node = Node.from_xml(request.raw_post)

      if new_node
        node.timestamp = Time.now
        node.user_id = @user.id

        node.latitude = new_node.latitude 
        node.longitude = new_node.longitude
        node.tags = new_node.tags

        if node.id == new_node.id and node.save_with_history
          render :nothing => true
        else
          render :nothing => true, :status => 500
        end
      else
        render :nothing => true, :status => 400 # if we got here the doc didnt parse
      end
      return
    end

  end

  def nodes
    response.headers["Content-Type"] = 'text/xml'
    ids = params['nodes'].split(',').collect {|n| n.to_i }
    if ids.length > 0
      nodelist = Node.find(ids)
      doc = get_xml_doc
      nodelist.each do |node|
        doc.root << node.to_xml_node
      end 
      render :text => doc.to_s
    else
      render :nothing => true, :status => 400
    end
  end
end
