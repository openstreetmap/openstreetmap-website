class NodeController < ApplicationController
  require 'xml/libxml'

  before_filter :authorize

  def create
    if request.put?
      p = XML::Parser.new
      p.string = request.raw_post
      doc = p.parse

      doc.find('//osm/node').each do |pt|
        lat = pt['lat'].to_f
        lon = pt['lon'].to_f
        node_id = pt['id'].to_i

        if lat > 90 or lat < -90 or lon > 180 or lon < -180  or node_id != 0
          render :nothing => true, :status => 400 # BAD REQUEST
          return
        end

        tags = []

        pt.find('tag').each do |tag|
          tags << [tag['k'],tag['v']]
        end
        tags = tags.collect { |k,v| "#{k}=#{v}" }.join(';')
        tags = '' if tags.nil?

        now = Time.now

        node = Node.new
        node.latitude = lat
        node.longitude = lon
        node.visible = 1
        node.tags = tags
        node.timestamp = now
        node.user_id = @user.id

        #FIXME add a node to the old nodes table too

        if node.save
          render :text => node.id
        else
          render :nothing => true, :status => 500
        end

        return
      end
    end

    render :nothing => true, :status => 400 # if we got here the doc didnt parse
  end

  def rest
    unless Node.exists?(params[:id])
      render :nothing => true, :status => 400
      return
    end

    node = Node.find(params[:id])


    case request.method
    when :get
      doc = XML::Document.new

      doc.encoding = "UTF-8"  
      root = XML::Node.new 'osm'
      root['version'] = '0.4'
      root['generator'] = 'OpenStreetMap server'
      doc.root = root
      el1 = XML::Node.new 'node'
      el1['id'] = node.id.to_s
      el1['lat'] = node.latitude.to_s
      el1['lon'] = node.longitude.to_s
      split_tags(el1, node.tags)
      el1['visible'] = node.visible.to_s
      el1['timestamp'] = node.timestamp.xmlschema
      root << el1

      render :text => doc.to_s

    when :delete
      #
      # DELETE
      #

      if node.visible
        node.visible = 0
        node.save
        render :nothing => true
      else
        render :nothing => true, :status => 410
      end

    when :put
      #
      # PUT
      #

      p = XML::Parser.new
      p.string = request.raw_post
      doc = p.parse

      doc.find('//osm/node').each do |pt|
        lat = pt['lat'].to_f
        lon = pt['lon'].to_f
        node_id = pt['id'].to_i

        if lat > 90 or lat < -90 or lon > 180 or lon < -180  or node_id != params[:id]
          render :nothing => true, :status => 400
          return
        end

        tags = []

        pt.find('tag').each do |tag|
          tags << [tag['k'],tag['v']]
        end
        tags = tags.collect { |k,v| "#{k}=#{v}" }.join(';')
        tags = '' if tags.nil?

        now = Time.now

        node.latitude = lat
        node.longitude = lon
        node.visible = 1
        node.tags = tags
        node.timestamp = now
        node.user_id = @user.id

        #FIXME add a node to the old nodes table too

        if node.save
          render :text => node.id
        else
          render :nothing => true, :status => 500
        end
      end
    end
  end

  private
  def split_tags(el, tags)
    tags.split(';').each do |tag|
      parts = tag.split('=')
      key = ''
      val = ''
      key = parts[0].strip unless parts[0].nil?
      val = parts[1].strip unless parts[1].nil?
      if key != '' && val != ''
        el2 = Node.new('tag')
        el2['k'] = key.to_s
        el2['v'] = val.to_s
        el << el2
      end
    end
  end


end
