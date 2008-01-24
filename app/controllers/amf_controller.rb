# AMF Controller is a semi-standalone API for Flash clients, particularly Potlatch.
# All interaction between Potlatch (as a .SWF application) and the 
# OSM database takes place using this controller. Messages are 
# encoded in the Actionscript Message Format (AMF).
#
# See Also Potlatch::Potlatch and Potlatch::AMF
#
# Public domain.
# editions Systeme D / Richard Fairhurst 2004-2008
#
# All in/out parameters are floats unless explicitly stated.
# 
# to trap errors (getway_old,putway,putpoi,deleteway only):
#   return(-1,"message")		<-- just puts up a dialogue
#   return(-2,"message")		<-- also asks the user to e-mail me
# to log:
#   RAILS_DEFAULT_LOGGER.error("Args: #{args[0]}, #{args[1]}, #{args[2]}, #{args[3]}")
class AmfController < ApplicationController
  require 'stringio'

  include Potlatch

  session :off
  before_filter :check_write_availability

  # Main AMF handler. Tha talk method takes in AMF, figures out what to do and dispatched to the appropriate private method
  def talk
    req=StringIO.new(request.raw_post+0.chr)	# Get POST data as request
    # (cf http://www.ruby-forum.com/topic/122163)
    req.read(2)									# Skip version indicator and client ID
    results={}									# Results of each body
    renumberednodes={}							# Shared across repeated putways

    # -------------
    # Parse request

    headers=AMF.getint(req)					# Read number of headers

    headers.times do				    # Read each header
      name=AMF.getstring(req)				#  |
      req.getc                 			#  | skip boolean
      value=AMF.getvalue(req)				#  |
      header["name"]=value				#  |
    end

    bodies=AMF.getint(req)					# Read number of bodies
    bodies.times do     				# Read each body
      message=AMF.getstring(req)			#  | get message name
      index=AMF.getstring(req)				#  | get index in response sequence
      bytes=AMF.getlong(req)				#  | get total size in bytes
      args=AMF.getvalue(req)				#  | get response (probably an array)

      case message
      when 'getpresets';		results[index]=AMF.putdata(index,getpresets)
      when 'whichways';			results[index]=AMF.putdata(index,whichways(args))
      when 'whichways_deleted';	results[index]=AMF.putdata(index,whichways_deleted(args))
      when 'getway';			results[index]=AMF.putdata(index,getway(args))
      when 'getway_old';		results[index]=AMF.putdata(index,getway_old(args))
      when 'getway_history';	results[index]=AMF.putdata(index,getway_history(args))
      when 'putway';			r=putway(args,renumberednodes)
        renumberednodes=r[3]
        results[index]=AMF.putdata(index,r)
      when 'deleteway';			results[index]=AMF.putdata(index,deleteway(args))
      when 'putpoi';			results[index]=AMF.putdata(index,putpoi(args))
      when 'getpoi';			results[index]=AMF.putdata(index,getpoi(args))
      end
    end

    # ------------------
    # Write out response

    RAILS_DEFAULT_LOGGER.info("  Response: start")
    a,b=results.length.divmod(256)
    render :content_type => "application/x-amf", :text => proc { |response, output| 
      output.write 0.chr+0.chr+0.chr+0.chr+a.chr+b.chr
      results.each do |k,v|
        output.write(v)
      end
    }
    RAILS_DEFAULT_LOGGER.info("  Response: end")
  end

  private

  # Return presets (default tags and crap) to potlatch.
  # Uses POTLATCH_PRESETS global, set up in OSM::Potlatch
  def getpresets #:doc:
    return POTLATCH_PRESETS
  end

  # ----- whichways
  # Find all the way ids and nodes (including tags and projected lat/lng) which aren't part of those ways in an are
  # 
  # The argument is an array containing the following, in order:
  # 0. minimum longitude
  # 1. minimum latitude
  # 2. maximum longitude
  # 3. maximum latitude
  # 4. baselong, 5. basey, 6. masterscale as above
  def whichways(args) #:doc:
    xmin = args[0].to_f-0.01
    ymin = args[1].to_f-0.01
    xmax = args[2].to_f+0.01
    ymax = args[3].to_f+0.01
    baselong    = args[4]
    basey       = args[5]
    masterscale = args[6]

    RAILS_DEFAULT_LOGGER.info("  Message: whichways, bbox=#{xmin},#{ymin},#{xmax},#{ymax}")

    # find the way ids in an area
    nodes_in_area = Node.find_by_area(ymin, xmin, ymax, xmax,:conditions => "visible = 1", :include => :way_nodes)
    waynodes_in_area = nodes_in_area.collect {|node| node.way_nodes }.flatten
    ways = waynodes_in_area.collect {|way_node| way_node.id[0]}.uniq

    # find the node ids in an area that aren't part of ways
    node_ids_in_area = nodes_in_area.collect {|node| node.id}.uniq
    node_ids_used_in_ways = waynodes_in_area.collect {|way_node| way_node.node_id}.uniq
    node_ids_not_used_in_area = node_ids_in_area - node_ids_used_in_ways
    nodes_not_used_in_area = Node.find(node_ids_not_used_in_area)
    points = nodes_not_used_in_area.collect {|n| [n.id, n.lon_potlatch(baselong,masterscale), n.lat_potlatch(basey,masterscale), n.tags_as_hash] }

    [ways,points]
  end

  # ----- whichways_deleted
  #		  return array of deleted ways in current bounding box
  #		  in:	as whichways
  #		  does: finds all deleted ways with a deleted node in bounding box
  #		  out:	[0] array of way ids
  def whichways_deleted(args) #:doc:
    xmin = args[0].to_f-0.01
    ymin = args[1].to_f-0.01
    xmax = args[2].to_f+0.01
    ymax = args[3].to_f+0.01
    baselong    = args[4]
    basey       = args[5]
    masterscale = args[6]

    sql=<<-EOF
     SELECT DISTINCT current_ways.id 
       FROM current_nodes,way_nodes,current_ways 
      WHERE #{OSM.sql_for_area(ymin, xmin, ymax, xmax, "current_nodes.")} 
      AND way_nodes.node_id=current_nodes.id 
      AND way_nodes.id=current_ways.id 
      AND current_nodes.visible=0 
      AND current_ways.visible=0 
  EOF
    waylist = ActiveRecord::Base.connection.select_all(sql)
    ways = waylist.collect {|a| a['id'].to_i }
    [ways]
  end

  # ----- getway
  # Get a way with all of it's nodes and tags
  # The input is an array with the following components, in order:
  # 0. wayid - the ID of the way to get
  # 1. baselong - origin of SWF map (longitude)
  # 2. basey - origin of SWF map (latitude)
  # 3. masterscale - SWF map scale
  #
  # The output is an array which contains all the nodes (with projected 
  # latitude and longitude) and tags for a way (and all the nodes tags). 
  # It also has the way's unprojected (WGS84) bbox.
  #
  # FIXME: The server really shouldn't be figuring out a ways bounding box and doing projection for potlatch
  # FIXME: the argument splitting should be done in the 'talk' method, not here
  def getway(args) #:doc:
    wayid,baselong,basey,masterscale = args
    wayid = wayid.to_i

    RAILS_DEFAULT_LOGGER.info("  Message: getway, id=#{wayid}")

    way = Way.find_eager(wayid)
    long_array = []
    lat_array = []
    points = []

    way.way_nodes.each do |way_node|
      node = way_node.node # get the node record
      projected_longitude = node.lon_potlatch(baselong,masterscale) # do projection for potlatch
      projected_latitude = node.lat_potlatch(basey,masterscale)
      id = node.id
      tags_hash = node.tags_as_hash

      points << [projected_longitude, projected_latitude, id, nil, tags_hash]
      long_array << projected_longitude
      lat_array << projected_latitude
    end

    [wayid,points,way.tags,long_array.min,long_array.max,lat_array.min,lat_array.max]
  end

  # ----- getway_old
  #		  returns old version of way
  #		  in:	[0] way id,
  #				[1] way version to get (or -1 for "last deleted version")
  #				[2] baselong, [3] basey, [4] masterscale
  #		  does:	gets old version of way and all constituent nodes
  #				for undelete, always uses the most recent version of each node
  #				  (even if it's moved)
  #				for revert, uses the historic version of each node, but if that node is
  #				  still visible and has been changed since, generates a new node id
  #		  out:	[0] 0 (code for success), [1] SWF object name,
  #				[2] array of points (as getway _except_ [3] is node.visible?, 0 or 1),
  #				[4] xmin, [5] xmax, [6] ymin, [7] ymax (unprojected bbox),
  #				[8] way version
  def getway_old(args) #:doc:
    RAILS_DEFAULT_LOGGER.info("  Message: getway_old (server is #{SERVER_URL})")
    #	if SERVER_URL=="www.openstreetmap.org" then return -1,"Revert is not currently enabled on the OpenStreetMap server." end

    wayid,version,baselong,basey,masterscale=args
    wayid = wayid.to_i
    version = version.to_i
    xmin = ymin =  999999
    xmax = ymax = -999999
    points=[]
    if version<0
      historic=false
      version=getlastversion(wayid,version)
    else
      historic=true
    end
    readwayquery_old(wayid,version,historic).each { |row|
      points<<[long2coord(row['longitude'].to_f,baselong,masterscale),lat2coord(row['latitude'].to_f,basey,masterscale),row['id'].to_i,row['visible'].to_i,tag2array(row['tags'].to_s)]
      xmin=[xmin,row['longitude'].to_f].min
      xmax=[xmax,row['longitude'].to_f].max
      ymin=[ymin,row['latitude' ].to_f].min
      ymax=[ymax,row['latitude' ].to_f].max
    }

    # get tags from this version
    attributes={}
    attrlist=ActiveRecord::Base.connection.select_all "SELECT k,v FROM way_tags WHERE id=#{wayid} AND version=#{version}"
    attrlist.each {|a| attributes[a['k'].gsub(':','|')]=a['v'] }
    attributes['history']="Retrieved from v"+version.to_s

    [0,wayid,points,attributes,xmin,xmax,ymin,ymax,version]
  end

  # ----- getway_history
  #		  find history of a way
  #		  in:	[0] way id
  #		  does:	finds history of a way
  #		  out:	[0] array of previous versions (where each is
  #					[0] version, [1] db timestamp (string),
  #					[2] visible 0 or 1,
  #					[3] username or 'anonymous' (string))
  def getway_history(args) #:doc:
    wayid=args[0]
    history=[]
    sql=<<-EOF
  SELECT version,timestamp,visible,display_name,data_public
    FROM ways,users
   WHERE ways.id=#{wayid}
     AND ways.user_id=users.id
     AND ways.visible=1
   ORDER BY version DESC
  EOF
    histlist=ActiveRecord::Base.connection.select_all(sql)
    histlist.each { |row|
      if row['data_public'].to_i==1 then user=row['display_name'] else user='anonymous' end
      history<<[row['version'],row['timestamp'],row['visible'],user]
    }
    [history]
  end

  # ----- putway
  #		  saves a way to the database
  #		  in:	[0] user token (string),
  #				[1] original way id (may be negative), 
  #				[2] array of points (as getway/getway_old),
  #				[3] hash of way tags,
  #				[4] original way version (0 if not a reverted/undeleted way),
  #				[5] baselong, [6] basey, [7] masterscale
  #		  does: saves way to the database
  #				all constituent nodes are created/updated as necessary
  #				(or deleted if they were in the old version and are otherwise unused)
  #		  out:	[0] 0 (code for success), [1] original way id (unchanged),
  #				[2] new way id, [3] hash of renumbered nodes (old id=>new id),
  #				[4] xmin, [5] xmax, [6] ymin, [7] ymax (unprojected bbox)
  def putway(args,renumberednodes) #:doc:
    RAILS_DEFAULT_LOGGER.info("  putway started")
    usertoken,originalway,points,attributes,oldversion,baselong,basey,masterscale=args
    uid=getuserid(usertoken)
    if !uid then return -1,"You are not logged in, so the way could not be saved." end

    RAILS_DEFAULT_LOGGER.info("  putway authenticated happily")
    db_uqn='unin'+(rand*100).to_i.to_s+uid.to_s+originalway.to_i.abs.to_s+Time.new.to_i.to_s	# temp uniquenodes table name, typically 51 chars
    db_now='@now'+(rand*100).to_i.to_s+uid.to_s+originalway.to_i.abs.to_s+Time.new.to_i.to_s	# 'now' variable name, typically 51 chars
    ActiveRecord::Base.connection.execute("SET #{db_now}=NOW()")
    originalway=originalway.to_i
    oldversion=oldversion.to_i

    RAILS_DEFAULT_LOGGER.info("  Message: putway, id=#{originalway}")

    # -- Temporary check for null IDs

    points.each do |a|
      if a[2]==0 or a[2].nil? then return -2,"Server error - node with id 0 found in way #{originalway}." end
    end

    # -- 3.	read original way into memory

    xc={}; yc={}; tagc={}; vc={}
    if originalway>0
      way=originalway
      if oldversion==0 then r=readwayquery(way,false)
      else r=readwayquery_old(way,oldversion,true) end
      r.each { |row|
        id=row['id'].to_i
        if (id>0) then
          xc[id]=row['longitude'].to_f
          yc[id]=row['latitude' ].to_f
          tagc[id]=row['tags']
          vc[id]=row['visible'].to_i
        end
      }
      ActiveRecord::Base.connection.update("UPDATE current_ways SET timestamp=#{db_now},user_id=#{uid},visible=1 WHERE id=#{way}")
    else
      way=ActiveRecord::Base.connection.insert("INSERT INTO current_ways (user_id,timestamp,visible) VALUES (#{uid},#{db_now},1)")
    end

    # -- 4.	get version by inserting new row into ways

    version=ActiveRecord::Base.connection.insert("INSERT INTO ways (id,user_id,timestamp,visible) VALUES (#{way},#{uid},#{db_now},1)")

    # -- 5. compare nodes and update xmin,xmax,ymin,ymax

    xmin=ymin= 999999
    xmax=ymax=-999999
    insertsql=''
    nodelist=[]

    points.each_index do |i|
      xs=coord2long(points[i][0],masterscale,baselong)
      ys=coord2lat(points[i][1],masterscale,basey)
      xmin=[xs,xmin].min; xmax=[xs,xmax].max
      ymin=[ys,ymin].min; ymax=[ys,ymax].max
      node=points[i][2].to_i
      tagstr=array2tag(points[i][4])
      tagsql="'"+sqlescape(tagstr)+"'"
      lat=(ys * 10000000).round
      long=(xs * 10000000).round
      tile=QuadTile.tile_for_point(ys, xs)

      # compare node
      if node<0
        # new node - create
        if renumberednodes[node.to_s].nil?
          newnode=ActiveRecord::Base.connection.insert("INSERT INTO current_nodes (   latitude,longitude,timestamp,user_id,visible,tags,tile) VALUES (           #{lat},#{long},#{db_now},#{uid},1,#{tagsql},#{tile})")
          ActiveRecord::Base.connection.insert("INSERT INTO nodes         (id,latitude,longitude,timestamp,user_id,visible,tags,tile) VALUES (#{newnode},#{lat},#{long},#{db_now},#{uid},1,#{tagsql},#{tile})")
          points[i][2]=newnode
          nodelist.push(newnode)
          renumberednodes[node.to_s]=newnode.to_s
        else
          points[i][2]=renumberednodes[node.to_s].to_i
        end

      elsif xc.has_key?(node)
        nodelist.push(node)
        # old node from original way - update
        if ((xs/0.0000001).round!=(xc[node]/0.0000001).round or (ys/0.0000001).round!=(yc[node]/0.0000001).round or tagstr!=tagc[node] or vc[node]==0)
          ActiveRecord::Base.connection.insert("INSERT INTO nodes (id,latitude,longitude,timestamp,user_id,visible,tags,tile) VALUES (#{node},#{lat},#{long},#{db_now},#{uid},1,#{tagsql},#{tile})")
          ActiveRecord::Base.connection.update("UPDATE current_nodes SET latitude=#{lat},longitude=#{long},timestamp=#{db_now},user_id=#{uid},tags=#{tagsql},visible=1,tile=#{tile} WHERE id=#{node}")
        end
      else
        # old node, created in another way and now added to this way
      end
    end

    # -- 6a. delete any nodes not in modified way

    createuniquenodes(way,db_uqn,nodelist)	# nodes which appear in this way but no other

    sql=<<-EOF
  INSERT INTO nodes (id,latitude,longitude,timestamp,user_id,visible,tile)  
  SELECT DISTINCT cn.id,cn.latitude,cn.longitude,#{db_now},#{uid},0,cn.tile
    FROM current_nodes AS cn,#{db_uqn}
   WHERE cn.id=node_id
    EOF
    ActiveRecord::Base.connection.insert(sql)

    sql=<<-EOF
      UPDATE current_nodes AS cn, #{db_uqn}
         SET cn.timestamp=#{db_now},cn.visible=0,cn.user_id=#{uid} 
       WHERE cn.id=node_id
    EOF
    ActiveRecord::Base.connection.update(sql)

    deleteuniquenoderelations(db_uqn,uid,db_now)
    ActiveRecord::Base.connection.execute("DROP TEMPORARY TABLE #{db_uqn}")

    #	6b. insert new version of route into way_nodes

    insertsql =''
    currentsql=''
    sequence  =1
    points.each do |p|
      if insertsql !='' then insertsql +=',' end
      if currentsql!='' then currentsql+=',' end
      insertsql +="(#{way},#{p[2]},#{sequence},#{version})"
      currentsql+="(#{way},#{p[2]},#{sequence})"
      sequence  +=1
    end

    ActiveRecord::Base.connection.execute("DELETE FROM current_way_nodes WHERE id=#{way}");
    ActiveRecord::Base.connection.insert( "INSERT INTO         way_nodes (id,node_id,sequence_id,version) VALUES #{insertsql}");
    ActiveRecord::Base.connection.insert( "INSERT INTO current_way_nodes (id,node_id,sequence_id        ) VALUES #{currentsql}");

    # -- 7. insert new way tags

    insertsql =''
    currentsql=''
    attributes.each do |k,v|
      if v=='' or v.nil? then next end
      if v[0,6]=='(type ' then next end
      if insertsql !='' then insertsql +=',' end
      if currentsql!='' then currentsql+=',' end
      insertsql +="(#{way},'"+sqlescape(k.gsub('|',':'))+"','"+sqlescape(v)+"',#{version})"
      currentsql+="(#{way},'"+sqlescape(k.gsub('|',':'))+"','"+sqlescape(v)+"')"
    end

    ActiveRecord::Base.connection.execute("DELETE FROM current_way_tags WHERE id=#{way}")
    if (insertsql !='') then ActiveRecord::Base.connection.insert("INSERT INTO way_tags (id,k,v,version) VALUES #{insertsql}" ) end
    if (currentsql!='') then ActiveRecord::Base.connection.insert("INSERT INTO current_way_tags (id,k,v) VALUES #{currentsql}") end

    [0,originalway,way,renumberednodes,xmin,xmax,ymin,ymax]
  end

  # ----- putpoi
  #		  save POI to the database
  #		  in:	[0] user token (string),
  #				[1] original node id (may be negative),
  #			  	[2] projected longitude, [3] projected latitude,
  #				[4] hash of tags, [5] visible (0 to delete, 1 otherwise), 
  #				[6] baselong, [7] basey, [8] masterscale
  #		  does:	saves POI node to the database
  #				refuses save if the node has since become part of a way
  #		  out:	[0] 0 (success), [1] original node id (unchanged),
  #				[2] new node id
  def putpoi(args) #:doc:
    usertoken,id,x,y,tags,visible,baselong,basey,masterscale=args
    uid=getuserid(usertoken)
    if !uid then return -1,"You are not logged in, so the point could not be saved." end

    db_now='@now'+(rand*100).to_i.to_s+uid.to_s+id.to_i.abs.to_s+Time.new.to_i.to_s	# 'now' variable name, typically 51 chars
    ActiveRecord::Base.connection.execute("SET #{db_now}=NOW()")

    id=id.to_i
    visible=visible.to_i
    if visible==0 then
      # if deleting, check node hasn't become part of a way 
      inway=ActiveRecord::Base.connection.select_one("SELECT cw.id FROM current_ways cw,current_way_nodes cwn WHERE cw.id=cwn.id AND cw.visible=1 AND cwn.node_id=#{id} LIMIT 1")
      unless inway.nil? then return -1,"The point has since become part of a way, so you cannot save it as a POI." end
      deleteitemrelations(id,'node',uid,db_now)
    end

    x=coord2long(x.to_f,masterscale,baselong)
    y=coord2lat(y.to_f,masterscale,basey)
    tagsql="'"+sqlescape(array2tag(tags))+"'"
    lat=(y * 10000000).round
    long=(x * 10000000).round
    tile=QuadTile.tile_for_point(y, x)

    if (id>0) then
      ActiveRecord::Base.connection.insert("INSERT INTO nodes (id,latitude,longitude,timestamp,user_id,visible,tags,tile) VALUES (#{id},#{lat},#{long},#{db_now},#{uid},#{visible},#{tagsql},#{tile})");
      ActiveRecord::Base.connection.update("UPDATE current_nodes SET latitude=#{lat},longitude=#{long},timestamp=#{db_now},user_id=#{uid},visible=#{visible},tags=#{tagsql},tile=#{tile} WHERE id=#{id}");
      newid=id
    else
      newid=ActiveRecord::Base.connection.insert("INSERT INTO current_nodes (latitude,longitude,timestamp,user_id,visible,tags,tile) VALUES (#{lat},#{long},#{db_now},#{uid},#{visible},#{tagsql},#{tile})");
      ActiveRecord::Base.connection.update("INSERT INTO nodes (id,latitude,longitude,timestamp,user_id,visible,tags,tile) VALUES (#{newid},#{lat},#{long},#{db_now},#{uid},#{visible},#{tagsql},#{tile})");
    end
    [0,id,newid]
  end

  # ----- getpoi
  #		  read POI from database
  #		  (only called on revert: POIs are usually read by whichways)
  #		  in:	[0] node id, [1] baselong, [2] basey, [3] masterscale
  #		  does: reads POI
  #		  out:	[0] id (unchanged), [1] projected long, [2] projected lat,
  #				[3] hash of tags
  def getpoi(args) #:doc:
    id,baselong,basey,masterscale=args; id=id.to_i
    poi=ActiveRecord::Base.connection.select_one("SELECT latitude*0.0000001 AS lat,longitude*0.0000001 AS lng,tags "+
    "FROM current_nodes WHERE visible=1 AND id=#{id}")
    if poi.nil? then return [nil,nil,nil,''] end
    [id,
      long2coord(poi['lng'].to_f,baselong,masterscale),
      lat2coord(poi['lat'].to_f,basey,masterscale),
      tag2array(poi['tags'])]
  end

  # ----- deleteway
  #		  delete way and constituent nodes from database
  #		  in:	[0] user token (string), [1] way id
  #		  does: deletes way from db and any constituent nodes not used elsewhere
  #				also removes ways/nodes from any relations they're in
  #		  out:	[0] 0 (success), [1] way id (unchanged)
  def deleteway(args) #:doc:

    usertoken,way=args

    RAILS_DEFAULT_LOGGER.info("  Message: deleteway, id=#{way}")
    uid=getuserid(usertoken)
    if !uid then return -1,"You are not logged in, so the way could not be deleted." end

    way=way.to_i
    db_uqn='unin'+(rand*100).to_i.to_s+uid.to_s+way.to_i.abs.to_s+Time.new.to_i.to_s	# temp uniquenodes table name, typically 51 chars
    db_now='@now'+(rand*100).to_i.to_s+uid.to_s+way.to_i.abs.to_s+Time.new.to_i.to_s	# 'now' variable name, typically 51 chars
    ActiveRecord::Base.connection.execute("SET #{db_now}=NOW()")

    # - delete any otherwise unused nodes

    createuniquenodes(way,db_uqn,[])

    #	unless (preserve.empty?) then
    #		ActiveRecord::Base.connection.execute("DELETE FROM #{db_uqn} WHERE node_id IN ("+preserve.join(',')+")")
    #	end

    sql=<<-EOF
  INSERT INTO nodes (id,latitude,longitude,timestamp,user_id,visible,tile)
  SELECT DISTINCT cn.id,cn.latitude,cn.longitude,#{db_now},#{uid},0,cn.tile
    FROM current_nodes AS cn,#{db_uqn}
   WHERE cn.id=node_id
    EOF
    ActiveRecord::Base.connection.insert(sql)

    sql=<<-EOF
      UPDATE current_nodes AS cn, #{db_uqn}
         SET cn.timestamp=#{db_now},cn.visible=0,cn.user_id=#{uid} 
       WHERE cn.id=node_id
    EOF
    ActiveRecord::Base.connection.update(sql)

    deleteuniquenoderelations(db_uqn,uid,db_now)
    ActiveRecord::Base.connection.execute("DROP TEMPORARY TABLE #{db_uqn}")

    # - delete way

    ActiveRecord::Base.connection.insert("INSERT INTO ways (id,user_id,timestamp,visible) VALUES (#{way},#{uid},#{db_now},0)")
    ActiveRecord::Base.connection.update("UPDATE current_ways SET user_id=#{uid},timestamp=#{db_now},visible=0 WHERE id=#{way}")
    ActiveRecord::Base.connection.execute("DELETE FROM current_way_nodes WHERE id=#{way}")
    ActiveRecord::Base.connection.execute("DELETE FROM current_way_tags WHERE id=#{way}")
    deleteitemrelations(way,'way',uid,db_now)
    [0,way]
  end

  def readwayquery(id,insistonvisible) #:doc:
    sql=<<-EOF
    SELECT latitude*0.0000001 AS latitude,longitude*0.0000001 AS longitude,current_nodes.id,tags,visible 
      FROM current_way_nodes,current_nodes 
     WHERE current_way_nodes.id=#{id} 
       AND current_way_nodes.node_id=current_nodes.id 
  EOF
    if insistonvisible then sql+=" AND current_nodes.visible=1 " end
    sql+=" ORDER BY sequence_id"
    ActiveRecord::Base.connection.select_all(sql)
  end

  def getlastversion(id,version) #:doc:
    row=ActiveRecord::Base.connection.select_one("SELECT version FROM ways WHERE id=#{id} AND visible=1 ORDER BY version DESC LIMIT 1")
    row['version']
  end

  def readwayquery_old(id,version,historic) #:doc:
    # Node handling on undelete (historic=false):
    # - always use the node specified, even if it's moved

    # Node handling on revert (historic=true):
    # - if it's a visible node, use a new node id (i.e. not mucking up the old one)
    #   which means the SWF needs to allocate new ids
    # - if it's an invisible node, we can reuse the old node id

    # get node list from specified version of way,
    # and the _current_ lat/long/tags of each node

    row=ActiveRecord::Base.connection.select_one("SELECT timestamp FROM ways WHERE version=#{version} AND id=#{id}")
    waytime=row['timestamp']

    sql=<<-EOF
  SELECT cn.id,visible,latitude*0.0000001 AS latitude,longitude*0.0000001 AS longitude,tags 
    FROM way_nodes wn,current_nodes cn 
   WHERE wn.version=#{version} 
     AND wn.id=#{id} 
     AND wn.node_id=cn.id 
   ORDER BY sequence_id
  EOF
    rows=ActiveRecord::Base.connection.select_all(sql)

    # if historic (full revert), get the old version of each node
    # - if it's in another way now, generate a new id
    # - if it's not in another way, use the old ID
    if historic then
      rows.each_index do |i|
        sql=<<-EOF
    SELECT latitude*0.0000001 AS latitude,longitude*0.0000001 AS longitude,tags,cwn.id AS currentway 
      FROM nodes n
   LEFT JOIN current_way_nodes cwn
      ON cwn.node_id=n.id
     WHERE n.id=#{rows[i]['id']} 
       AND n.timestamp<="#{waytime}" 
     AND cwn.id!=#{id} 
     ORDER BY n.timestamp DESC 
     LIMIT 1
    EOF
        row=ActiveRecord::Base.connection.select_one(sql)
        unless row.nil? then
          nx=row['longitude'].to_f
          ny=row['latitude'].to_f
          if (row['currentway'] && (nx!=rows[i]['longitude'].to_f or ny!=rows[i]['latitude'].to_f or row['tags']!=rows[i]['tags'])) then rows[i]['id']=-1 end
          rows[i]['longitude']=nx
          rows[i]['latitude' ]=ny
          rows[i]['tags'     ]=row['tags']
        end
      end
    end
    rows
  end

  def createuniquenodes(way,uqn_name,nodelist) #:doc:
    # Find nodes which appear in this way but no others
    sql=<<-EOF
  CREATE TEMPORARY TABLE #{uqn_name}
          SELECT a.node_id
            FROM (SELECT DISTINCT node_id FROM current_way_nodes
              WHERE id=#{way}) a
         LEFT JOIN current_way_nodes b
            ON b.node_id=a.node_id
             AND b.id!=#{way}
           WHERE b.node_id IS NULL
  EOF
    unless nodelist.empty? then
      sql+="AND a.node_id NOT IN ("+nodelist.join(',')+")"
    end
    ActiveRecord::Base.connection.execute(sql)
  end



  # ====================================================================
  # Relations handling
  # deleteuniquenoderelations(uqn_name,uid,db_now)
  # deleteitemrelations(way|node,'way'|'node',uid,db_now)

  def deleteuniquenoderelations(uqn_name,uid,db_now) #:doc:
    sql=<<-EOF
  SELECT node_id,cr.id FROM #{uqn_name},current_relation_members crm,current_relations cr 
   WHERE crm.member_id=node_id 
     AND crm.member_type='node' 
     AND crm.id=cr.id 
     AND cr.visible=1
  EOF

    relnodes=ActiveRecord::Base.connection.select_all(sql)
    relnodes.each do |a|
      removefromrelation(a['node_id'],'node',a['id'],uid,db_now)
    end
  end

  def deleteitemrelations(objid,type,uid,db_now) #:doc:
    sql=<<-EOF
  SELECT cr.id FROM current_relation_members crm,current_relations cr 
   WHERE crm.member_id=#{objid} 
     AND crm.member_type='#{type}' 
     AND crm.id=cr.id 
     AND cr.visible=1
  EOF

    relways=ActiveRecord::Base.connection.select_all(sql)
    relways.each do |a|
      removefromrelation(objid,type,a['id'],uid,db_now)
    end
  end

  def removefromrelation(objid,type,relation,uid,db_now) #:doc:
    rver=ActiveRecord::Base.connection.insert("INSERT INTO relations (id,user_id,timestamp,visible) VALUES (#{relation},#{uid},#{db_now},1)")

    tagsql=<<-EOF
  INSERT INTO relation_tags (id,k,v,version) 
  SELECT id,k,v,#{rver} FROM current_relation_tags 
   WHERE id=#{relation} 
  EOF
    ActiveRecord::Base.connection.insert(tagsql)

    membersql=<<-EOF
  INSERT INTO relation_members (id,member_type,member_id,member_role,version) 
  SELECT id,member_type,member_id,member_role,#{rver} FROM current_relation_members 
   WHERE id=#{relation} 
     AND (member_id!=#{objid} OR member_type!='#{type}')
  EOF
    ActiveRecord::Base.connection.insert(membersql)

    ActiveRecord::Base.connection.update("UPDATE current_relations SET user_id=#{uid},timestamp=#{db_now} WHERE id=#{relation}")
    ActiveRecord::Base.connection.execute("DELETE FROM current_relation_members WHERE id=#{relation} AND member_type='#{type}' AND member_id=#{objid}")
  end

  def sqlescape(a) #:doc:
    a.gsub(/[\000-\037]/,"").gsub("'","''").gsub(92.chr) {92.chr+92.chr}
  end

  def tag2array(a) #:doc:
    tags={}
    Tags.split(a) do |k, v|
      tags[k.gsub(':','|')]=v
    end
    tags
  end

  def array2tag(a) #:doc:
    tags = []
    a.each do |k,v|
      if v=='' then next end
      if v[0,6]=='(type ' then next end
      tags << [k.gsub('|',':'), v]
    end
    return Tags.join(tags)
  end

  def getuserid(token) #:doc:
    if (token =~ /^(.+)\+(.+)$/) then
      user = User.authenticate(:username => $1, :password => $2)
    else
      user = User.authenticate(:token => token)
    end

    return user ? user.id : nil;
  end

  # ====================================================================
  # Co-ordinate conversion

  def lat2coord(a,basey,masterscale) #:doc:
    -(lat2y(a)-basey)*masterscale+250
  end

  def long2coord(a,baselong,masterscale) #:doc:
    (a-baselong)*masterscale+350
  end

  def lat2y(a) #:doc:
    180/Math::PI * Math.log(Math.tan(Math::PI/4+a*(Math::PI/180)/2))
  end

  def coord2lat(a,masterscale,basey) #:doc:
    y2lat((a-250)/-masterscale+basey)
  end

  def coord2long(a,masterscale,baselong) #:doc:
    (a-350)/masterscale+baselong
  end

  def y2lat(a)
    180/Math::PI * (2*Math.atan(Math.exp(a*Math::PI/180))-Math::PI/2)
  end

end
