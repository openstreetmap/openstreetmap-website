class NodeController < ApplicationController
  require 'xml/libxml'
  
  before_filter :authorize

  def create
    @node = Node.new
    @node.id = 1
    @node.latitude = 1
    @node.save
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


  def rest

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
      doc = Document.new
      doc.encoding = "UTF-8"
      root = Node.new 'osm'
      root['version'] = '0.4'
      root['generator'] = 'OpenStreetMap server'
      doc.root = root
      el1 = Node.new 'node'
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
