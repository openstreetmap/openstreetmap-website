class NodeController < ApplicationController
  require 'xml/libxml'
  
  before_filter :authorize

  def create
    if request.put?
      doc = XML::Document.new(request.raw_post) #THIS IS BROKEN, libxml docus dont talk about creating a doc from a string
      doc.find('//osm/node').each do |pt|
        render :text => 'arghsd.rkugt;dsrt'
        return
        lat = pt.attributes['lat'].to_f
        lon = pt.attributes['lon'].to_f
        node_id = pt.attributes['id'].to_i

        if lat > 90 or lat < -90 or lon > 180 or lon < -180  or node_id != 0
          render :nothing => true, :status => 400 # BAD REQUEST
          return
        end

        tags = []

        pt.elements.each('tag') do |tag|
          tags << [tag.attributes['k'],tag.attributes['v']]
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
      end
    end

        render :text => 'WRONG!           '
        return

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

      # this needs a new libxml:
      # doc.encoding = "UTF-8"  

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

      #
      # DELETE
      #
    when :delete

      if node.visible
        node.visible = 0
        node.save
      else
        render :nothing => true, :status => 410
      end

      #
      # PUT
      #
    when :put

      doc = XML::Document.new(request.raw_post)
      doc.elements.each('osm/node') do |pt|
        lat = pt.attributes['lat'].to_f
        lon = pt.attributes['lon'].to_f
        node_id = pt.attributes['id'].to_i

        if lat > 90 or lat < -90 or lon > 180 or lon < -180  or node_id != params[:id]
          render :nothing => true, :status => 400 # BAD REQUEST
          return
        end

        tags = []

        pt.elements.each('tag') do |tag|
          tags << [tag.attributes['k'],tag.attributes['v']]
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


  def dummy
    if request.post?
      userid = dao.useridfromcreds(r.user, r.get_basic_auth_pw)
      doc = Document.new $stdin.read

      doc.elements.each('osm/node') do |pt|
        lat = pt.attributes['lat'].to_f
        lon = pt.attributes['lon'].to_f
        xmlnodeid = pt.attributes['id'].to_i

        tags = []
        pt.elements.each('tag') do |tag|
          tags << [tag.attributes['k'],tag.attributes['v']]
        end

        tags = tags.collect { |k,v| "#{k}=#{v}" }.join(';')

        tags = '' unless tags
        if xmlnodeid == nodeid && userid != 0
          if nodeid == 0
            new_node_id = dao.create_node(lat, lon, userid, tags)
            if new_node_id
              puts new_node_id
              exit
            else
              exit HTTP_INTERNAL_SERVER_ERROR
            end
          else
            node = dao.getnode(nodeid)
            if node
              #FIXME: need to check the node hasn't moved too much
              if dao.update_node?(nodeid, userid, lat, lon, tags)
                exit
              else
                exit HTTP_INTERNAL_SERVER_ERROR
              end
            else
              exit HTTP_NOT_FOUND
            end
          end

        else
          exit BAD_REQUEST
        end
      end
      exit HTTP_INTERNAL_SERVER_ERROR


    end
  end


  def dummydummy

    #
    # POST ???
    #

    if request.post?
      nodeid = r.args.match(/nodeid=([0-9]+)/).captures.first.to_i
      userid = dao.useridfromcreds(r.user, r.get_basic_auth_pw)
      doc = Document.new $stdin.read

      doc.elements.each('osm/node') do |pt|
        lat = pt.attributes['lat'].to_f
        lon = pt.attributes['lon'].to_f
        xmlnodeid = pt.attributes['id'].to_i

        tags = []
        pt.elements.each('tag') do |tag|
          tags << [tag.attributes['k'],tag.attributes['v']]
        end

        tags = tags.collect { |k,v| "#{k}=#{v}" }.join(';')

        tags = '' unless tags
        if xmlnodeid == nodeid && userid != 0
          if nodeid == 0
            new_node_id = dao.create_node(lat, lon, userid, tags)
            if new_node_id
              puts new_node_id
              exit
            else
              exit HTTP_INTERNAL_SERVER_ERROR
            end
          else
            node = dao.getnode(nodeid)
            if node
              #FIXME: need to check the node hasn't moved too much
              if dao.update_node?(nodeid, userid, lat, lon, tags)
                exit
              else
                exit HTTP_INTERNAL_SERVER_ERROR
              end
            else
              exit HTTP_NOT_FOUND
            end
          end

        else
          exit BAD_REQUEST
        end
      end
      exit HTTP_INTERNAL_SERVER_ERROR

    end

    #
    # GET ???
    #

    if request.get?
      node = node.find(params[:id])
      doc = document.new
      doc.encoding = "utf-8"
      root = node.new 'osm'
      root['version'] = '0.4'
      root['generator'] = 'openstreetmap server'
      doc.root = root
      el1 = node.new 'node'
      el1['id'] = node.id.to_s
      el1['lat'] = node.latitude.to_s
      el1['lon'] = node.longitude.to_s
      split_tags(el1, node.tags)
      el1['visible'] = node.visible.to_s
      el1['timestamp'] = node.timestamp
      root << el1

      render :text => doc.to_s, :template => false
    end

    #
    # DELETE????
    # 

    if request.delete?
      userid = dao.useridfromcreds(r.user, r.get_basic_auth_pw)
      #cgi doesnt work with DELETE so extract manually:
      nodeid = r.args.match(/nodeid=([0-9]+)/).captures.first.to_i

      if userid > 0 && nodeid != 0
        node = dao.getnode(nodeid)
        if node
          if node.visible  
            if dao.delete_node?(nodeid, userid)
              exit
            else
              exit HTTP_INTERNAL_SERVER_ERROR
            end
          else
            exit HTTP_GONE
          end
        else
          exit HTTP_NOT_FOUND
        end
      else
        exit BAD_REQUEST

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
