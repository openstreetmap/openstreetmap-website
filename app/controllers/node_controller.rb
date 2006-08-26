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
    unless Node.exists?(params[:id])
      render :nothing => true, :status => 400
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
        node.visible = 0
        node.save_with_history
        render :nothing => true
      else
        render :nothing => true, :status => 410
      end

    when :put
      new_node = Node.from_xml(request.raw_post)

      node.timestamp = Time.now
      node.user_id = @user.id

      node.latitude = new_node.latitude 
      node.longitude = new_node.longitude
      node.tags = new_node.tags

      if node.id == new_node.id and node.save_with_history
        render :nothing => true, :status => 200
      else
        render :nothing => true, :status => 500
      end
      return
    end

  end

  def history
    node = Node.find(params[:id])

    unless node
      render :nothing => true, :staus => 404
      return
    end

    doc = XML::Document.new
    doc.encoding = 'UTF-8' 
    root = XML::Node.new 'osm'
    root['version'] = '0.4'
    root['generator'] = 'OpenStreetMap server'
    doc.root = root

    node.old_nodes.each do |old_node|
      el1 = XML::Node.new 'node'
      el1['id'] = old_node.id.to_s
      el1['lat'] = old_node.latitude.to_s
      el1['lon'] = old_node.longitude.to_s
      Node.split_tags(el1, old_node.tags)
      el1['visible'] = old_node.visible.to_s
      el1['timestamp'] = old_node.timestamp.xmlschema
      root << el1
    end

    render :text => doc.to_s
  end
end
