class AmfController < ApplicationController
  require 'stringio'

  session :off
  before_filter :check_write_availability

  # AMF controller for Potlatch
  # ---------------------------
  # All interaction between Potlatch (as a .SWF application) and the 
  # OSM database takes place using this controller. Messages are 
  # encoded in the Actionscript Message Format (AMF).
  #
  # Public domain. Set your tab width to 4 to read this document. :)
  # editions Systeme D / Richard Fairhurst 2004-2007
  
  # to trap errors (getway_old,putway,putpoi,deleteway only):
  #   return(-1,"message")		<-- just puts up a dialogue
  #   return(-2,"message")		<-- also asks the user to e-mail me
  # to log:
  #   RAILS_DEFAULT_LOGGER.error("Args: #{args[0]}, #{args[1]}, #{args[2]}, #{args[3]}")

  # ====================================================================
  # Main AMF handler

  # ---- talk	process AMF request

  def talk
    req=StringIO.new(request.raw_post+0.chr)	# Get POST data as request
    											# (cf http://www.ruby-forum.com/topic/122163)
    req.read(2)									# Skip version indicator and client ID
    results={}									# Results of each body
    renumberednodes={}							# Shared across repeated putways

    # -------------
    # Parse request

    headers=getint(req)					# Read number of headers

    headers.times do				    # Read each header
      name=getstring(req)				#  |
      req.getc                 			#  | skip boolean
      value=getvalue(req)				#  |
      header["name"]=value				#  |
    end

    bodies=getint(req)					# Read number of bodies
    bodies.times do     				# Read each body
      message=getstring(req)			#  | get message name
      index=getstring(req)				#  | get index in response sequence
      bytes=getlong(req)				#  | get total size in bytes
      args=getvalue(req)				#  | get response (probably an array)

      case message
		  when 'getpresets';		results[index]=putdata(index,getpresets)
		  when 'whichways';			results[index]=putdata(index,whichways(args))
		  when 'whichways_deleted';	results[index]=putdata(index,whichways_deleted(args))
		  when 'getway';			results[index]=putdata(index,getway(args))
		  when 'getway_old';		results[index]=putdata(index,getway_old(args))
		  when 'getway_history';	results[index]=putdata(index,getway_history(args))
		  when 'putway';			r=putway(args,renumberednodes)
		  							renumberednodes=r[3]
		  							results[index]=putdata(index,r)
		  when 'deleteway';			results[index]=putdata(index,deleteway(args))
		  when 'putpoi';			results[index]=putdata(index,putpoi(args))
		  when 'getpoi';			results[index]=putdata(index,getpoi(args))
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

  # ====================================================================
  # Remote calls

  # ----- getpresets
  #	      return presets,presetmenus and presetnames arrays

  def getpresets
    presets={}
    presetmenus={}; presetmenus['point']=[]; presetmenus['way']=[]; presetmenus['POI']=[]
    presetnames={}; presetnames['point']={}; presetnames['way']={}; presetnames['POI']={}
    presettype=''
    presetcategory=''

    RAILS_DEFAULT_LOGGER.info("  Message: getpresets")

    #		File.open("config/potlatch/presets.txt") do |file|

    # Temporary patch to get around filepath problem
    # To remove this patch and make the code nice again:
    # 1. uncomment above line
    # 2. fix the path in the above line
    # 3. delete this here document, and the following line (StringIO....)

    txt=<<-EOF
way/road
motorway: highway=motorway,ref=(type road number)
trunk road: highway=trunk,ref=(type road number),name=(type road name)
primary road: highway=primary,ref=(type road number),name=(type road name)
secondary road: highway=secondary,ref=(type road number),name=(type road name)
tertiary road: highway=tertiary,ref=,name=(type road name)
residential road: highway=residential,ref=,name=(type road name)
unclassified road: highway=unclassified,ref=,name=(type road name)

way/footway
footpath: highway=footway,foot=yes
bridleway: highway=bridleway,foot=yes
byway: highway=unsurfaced,foot=yes
permissive path: highway=footway,foot=permissive

way/cycleway
cycle lane: highway=cycleway,cycleway=lane,ncn_ref=
cycle track: highway=cycleway,cycleway=track,ncn_ref=
cycle lane (NCN): highway=cycleway,cycleway=lane,name=(type name here),ncn_ref=(type route number)
cycle track (NCN): highway=cycleway,cycleway=track,name=(type name here),ncn_ref=(type route number)

way/waterway
canal: waterway=canal,name=(type name here)
navigable river: waterway=river,boat=yes,name=(type name here)
navigable drain: waterway=drain,boat=yes,name=(type name here)
derelict canal: waterway=derelict_canal,name=(type name here)
unnavigable river: waterway=river,boat=no,name=(type name here)
unnavigable drain: waterway=drain,boat=no,name=(type name here)
stream: waterway=stream,boat=no,name=(type name here)

way/railway
railway: railway=rail
tramway: railway=tram
light railway: railway=light_rail
preserved railway: railway=preserved
disused railway tracks: railway=disused
course of old railway: railway=abandoned

way/natural
lake: natural=water,landuse=
forest: landuse=forest,natural=

point/road
mini roundabout: highway=mini_roundabout
traffic lights: highway=traffic_signals

point/footway
bridge: highway=bridge
gate: highway=gate
stile: highway=stile
cattle grid: highway=cattle_grid

point/cycleway
gate: highway=gate

point/waterway
lock gate: waterway=lock_gate
weir: waterway=weir
aqueduct: waterway=aqueduct
winding hole: waterway=turning_point
mooring: waterway=mooring

point/railway
station: railway=station
viaduct: railway=viaduct
level crossing: railway=crossing

point/natural
peak: natural=peak

POI/road
car park: amenity=parking
petrol station: amenity=fuel

POI/cycleway
bike park: amenity=bicycle_parking

POI/place
city: place=city,name=(type name here),is_in=(type region or county)
town: place=town,name=(type name here),is_in=(type region or county)
suburb: place=suburb,name=(type name here),is_in=(type region or county)
village: place=village,name=(type name here),is_in=(type region or county)
hamlet: place=hamlet,name=(type name here),is_in=(type region or county)

POI/tourism
attraction: tourism=attraction,amenity=,religion=,denomination=
church: tourism=,amenity=place_of_worship,name=(type name here),religion=christian,denomination=(type denomination here)
hotel: tourism=hotel,amenity=,religion=,denomination=
other religious: tourism=,amenity=place_of_worship,name=(type name here),religion=(type religion),denomination=
post box: amenity=post_box,tourism=,name=,religion=,denomination=
post office: amenity=post_office,tourism=,name=,religion=,denomination=
pub: tourism=,amenity=pub,name=(type name here),religion=,denomination=

POI/natural
peak: natural=peak
EOF

    StringIO.open(txt) do |file|
      file.each_line {|line|
        t=line.chomp
        if (t=~/(\w+)\/(\w+)/) then
          presettype=$1
          presetcategory=$2
          presetmenus[presettype].push(presetcategory)
          presetnames[presettype][presetcategory]=["(no preset)"]
        elsif (t=~/^(.+):\s?(.+)$/) then
          pre=$1; kv=$2
          presetnames[presettype][presetcategory].push(pre)
          presets[pre]={}
          kv.split(',').each {|a|
            if (a=~/^(.+)=(.*)$/) then presets[pre][$1]=$2 end
          }
        end
      }
    end
    [presets,presetmenus,presetnames]
  end

  # ----- whichways(left,bottom,right,top)
  #		  return array of ways in current bounding box
  #		  at present, instead of using correct (=more complex) SQL to find
  #		  corner-crossing ways, it simply enlarges the bounding box by +/- 0.01

  def whichways(args)
    xmin = args[0].to_f-0.01
    ymin = args[1].to_f-0.01
    xmax = args[2].to_f+0.01
    ymax = args[3].to_f+0.01
    baselong    = args[4]
    basey       = args[5]
    masterscale = args[6]

    RAILS_DEFAULT_LOGGER.info("  Message: whichways, bbox=#{xmin},#{ymin},#{xmax},#{ymax}")

    waylist = ActiveRecord::Base.connection.select_all("SELECT DISTINCT current_way_nodes.id AS wayid"+
       "  FROM current_way_nodes,current_nodes,current_ways "+
       " WHERE current_nodes.id=current_way_nodes.node_id "+
       "   AND current_nodes.visible=1 "+
       "   AND current_ways.id=current_way_nodes.id "+
       "   AND current_ways.visible=1 "+
       "   AND "+OSM.sql_for_area(ymin, xmin, ymax, xmax, "current_nodes."))

    ways = waylist.collect {|a| a['wayid'].to_i } # get an array of way IDs

    pointlist = ActiveRecord::Base.connection.select_all("SELECT current_nodes.id,current_nodes.latitude*0.0000001 AS lat,current_nodes.longitude*0.0000001 AS lng,current_nodes.tags "+
       "  FROM current_nodes "+
       "  LEFT OUTER JOIN current_way_nodes cwn ON cwn.node_id=current_nodes.id "+
       " WHERE "+OSM.sql_for_area(ymin, xmin, ymax, xmax, "current_nodes.")+
       "   AND cwn.id IS NULL "+
       "   AND current_nodes.visible=1")

    points = pointlist.collect {|a| [a['id'],long2coord(a['lng'].to_f,baselong,masterscale),lat2coord(a['lat'].to_f,basey,masterscale),tag2array(a['tags'])]	} # get a list of node ids and their tags

    [ways,points]
  end

  # ----- whichways_deleted(left,bottom,right,top)
  #		  return array of deleted ways in current bounding box
  
  def whichways_deleted(args)
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
  
  # ----- getway (objectname, way, baselong, basey, masterscale)
  #		  returns objectname, array of co-ordinates, attributes,
  #				  xmin,xmax,ymin,ymax

  def getway(args)
    objname,wayid,baselong,basey,masterscale=args
    wayid = wayid.to_i
    points = []
    xmin = ymin =  999999
    xmax = ymax = -999999

    RAILS_DEFAULT_LOGGER.info("  Message: getway, id=#{wayid}")

    readwayquery(wayid).each {|row|
      points<<[long2coord(row['longitude'].to_f,baselong,masterscale),lat2coord(row['latitude'].to_f,basey,masterscale),row['id'].to_i,nil,tag2array(row['tags'])]
      xmin = [xmin,row['longitude'].to_f].min
      xmax = [xmax,row['longitude'].to_f].max
      ymin = [ymin,row['latitude'].to_f].min
      ymax = [ymax,row['latitude'].to_f].max
    }

    attributes={}
    attrlist=ActiveRecord::Base.connection.select_all "SELECT k,v FROM current_way_tags WHERE id=#{wayid}"
    attrlist.each {|a| attributes[a['k'].gsub(':','|')]=a['v'] }

    [objname,points,attributes,xmin,xmax,ymin,ymax]
  end
  
  # -----	getway_old (objectname, way, version, baselong, basey, masterscale)
  #			returns old version of way

  def getway_old(args)
    RAILS_DEFAULT_LOGGER.info("  Message: getway_old (server is #{SERVER_URL})")
	if SERVER_URL=="www.openstreetmap.org" then return -1,"Revert is not currently enabled on the OpenStreetMap server." end
	
    objname,wayid,version,baselong,basey,masterscale=args
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

    [0,objname,points,attributes,xmin,xmax,ymin,ymax,version]
  end

  # -----	getway_history (way)
  #			returns array of previous versions (version,timestamp,visible,user)
  #			should also show 'created_by'

  def getway_history(wayid)
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
		if row['data_public'] then user=row['display_name'] else user='anonymous' end
		history<<[row['version'],row['timestamp'],row['visible'],user]
	}
	[history]
  end

  # -----	putway (user token, way, array of co-ordinates, array of attributes,
  #					baselong, basey, masterscale)
  #			returns current way ID, new way ID, hash of renumbered nodes,
  #					xmin,xmax,ymin,ymax

  def putway(args,renumberednodes)
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
	  if oldversion==0
	    readwayquery(way).each { |row|
		  id=row['id'].to_i
		  xc[id]=row['longitude'].to_f
		  yc[id]=row['latitude' ].to_f
		  tagc[id]=row['tags']
		  vc[id]=1
		}
	  else
	    readwayquery_old(way,oldversion,true).each { |row|
		  id=row['id'].to_i
		  if (id>0) then
			xc[id]=row['longitude'].to_f
			yc[id]=row['latitude' ].to_f
			tagc[id]=row['tags']
			vc[id]=row['visible'].to_i
		  end
		}
	  end
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
        if (xs!=xc[node] or (ys/0.0000001).round!=(yc[node]/0.0000001).round or tagstr!=tagc[node] or vc[node]==0)
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
    ActiveRecord::Base.connection.execute("DROP TABLE #{db_uqn}")

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

  # -----	putpoi (user token, id, x,y,tag array,visible,baselong,basey,masterscale)
  #			returns current id, new id
  #			if new: add new row to current_nodes and nodes
  #			if old: add new row to nodes, update current_nodes

  def putpoi(args)
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

  # -----	getpoi (id,baselong,basey,masterscale)
  #			returns id,x,y,tag array
  
  def getpoi(args)
	id,baselong,basey,masterscale=args; id=id.to_i
	poi=ActiveRecord::Base.connection.select_one("SELECT latitude*0.0000001 AS lat,longitude*0.0000001 AS lng,tags "+
		"FROM current_nodes WHERE visible=1 AND id=#{id}")
	if poi.nil? then return [nil,nil,nil,''] end
	[id,
	 long2coord(poi['lng'].to_f,baselong,masterscale),
	 lat2coord(poi['lat'].to_f,basey,masterscale),
	 tag2array(poi['tags'])]
  end

  # -----	deleteway (user token, way, nodes to keep)
  #			returns way ID only

  def deleteway(args)
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
    ActiveRecord::Base.connection.execute("DROP TABLE #{db_uqn}")

    # - delete way
	
    ActiveRecord::Base.connection.insert("INSERT INTO ways (id,user_id,timestamp,visible) VALUES (#{way},#{uid},#{db_now},0)")
    ActiveRecord::Base.connection.update("UPDATE current_ways SET user_id=#{uid},timestamp=#{db_now},visible=0 WHERE id=#{way}")
    ActiveRecord::Base.connection.execute("DELETE FROM current_way_nodes WHERE id=#{way}")
    ActiveRecord::Base.connection.execute("DELETE FROM current_way_tags WHERE id=#{way}")
	deleteitemrelations(way,'way',uid,db_now)
    [0,way]
end



# ====================================================================
# Support functions for remote calls

def readwayquery(id)
  ActiveRecord::Base.connection.select_all "SELECT latitude*0.0000001 AS latitude,longitude*0.0000001 AS longitude,current_nodes.id,tags "+
      "    FROM current_way_nodes,current_nodes "+
      "   WHERE current_way_nodes.id=#{id} "+
      "     AND current_way_nodes.node_id=current_nodes.id "+
      "     AND current_nodes.visible=1 "+
      "   ORDER BY sequence_id"
end

def getlastversion(id,version)
  row=ActiveRecord::Base.connection.select_one("SELECT version FROM ways WHERE id=#{id} AND visible=1 ORDER BY version DESC LIMIT 1")
  row['version']
end

def readwayquery_old(id,version,historic)
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
	    if (row['currentway']) then rows[i]['id']=-1 end
		rows[i]['longitude']=nx
		rows[i]['latitude' ]=ny
		rows[i]['tags'     ]=row['tags']
	  end
    end
  end
  rows
end

def createuniquenodes(way,uqn_name,nodelist)
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

def deleteuniquenoderelations(uqn_name,uid,db_now)
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

def deleteitemrelations(objid,type,uid,db_now)
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

def removefromrelation(objid,type,relation,uid,db_now)
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


def sqlescape(a)
  a.gsub(/[\000-\037]/,"").gsub("'","''").gsub(92.chr) {92.chr+92.chr}
end

def tag2array(a)
  tags={}
  Tags.split(a) do |k, v|
    tags[k.gsub(':','|')]=v
  end
  tags
end

def array2tag(a)
  tags = []
  a.each do |k,v|
    if v=='' then next end
    if v[0,6]=='(type ' then next end
    tags << [k.gsub('|',':'), v]
  end
  return Tags.join(tags)
end

def getuserid(token)
  if (token =~ /^(.+)\+(.+)$/) then
    user = User.authenticate(:username => $1, :password => $2)
  else
    user = User.authenticate(:token => token)
  end

  return user ? user.id : nil;
end



# ====================================================================
# AMF read subroutines

# -----	getint		return two-byte integer
# -----	getlong		return four-byte long
# -----	getstring	return string with two-byte length
# ----- getdouble	return eight-byte double-precision float
# ----- getobject	return object/hash
# ----- getarray	return numeric array

def getint(s)
  s.getc*256+s.getc
end

def getlong(s)
  ((s.getc*256+s.getc)*256+s.getc)*256+s.getc
end

def getstring(s)
  len=s.getc*256+s.getc
  s.read(len)
end

def getdouble(s)
  a=s.read(8).unpack('G')			# G big-endian, E little-endian
  a[0]
end

def getarray(s)
  len=getlong(s)
  arr=[]
  for i in (0..len-1)
    arr[i]=getvalue(s)
  end
  arr
end

def getobject(s)
  arr={}
  while (key=getstring(s))
    if (key=='') then break end
    arr[key]=getvalue(s)
  end
  s.getc		# skip the 9 'end of object' value
  arr
end

# -----	getvalue	parse and get value

def getvalue(s)
  case s.getc
	when 0;	return getdouble(s)			# number
	when 1;	return s.getc				# boolean
	when 2;	return getstring(s)			# string
	when 3;	return getobject(s)			# object/hash
	when 5;	return nil					# null
	when 6;	return nil					# undefined
	when 8;	s.read(4)					# mixedArray
			return getobject(s)			#  |
	when 10;return getarray(s)			# array
	else;	return nil					# error
  end
end

# ====================================================================
# AMF write subroutines

# -----	putdata		envelope data into AMF writeable form
# -----	encodevalue	pack variables as AMF

def putdata(index,n)
  d =encodestring(index+"/onResult")
  d+=encodestring("null")
  d+=[-1].pack("N")
  d+=encodevalue(n)
end

def encodevalue(n)
  case n.class.to_s
  when 'Array'
    a=10.chr+encodelong(n.length)
    n.each do |b|
      a+=encodevalue(b)
    end
    a
  when 'Hash'
    a=3.chr
    n.each do |k,v|
      a+=encodestring(k)+encodevalue(v)
    end
    a+0.chr+0.chr+9.chr
  when 'String'
    2.chr+encodestring(n)
  when 'Bignum','Fixnum','Float'
    0.chr+encodedouble(n)
  when 'NilClass'
    5.chr
  else
    RAILS_DEFAULT_LOGGER.error("Unexpected Ruby type for AMF conversion: "+n.class.to_s)
  end
end

# -----	encodestring	encode string with two-byte length
# -----	encodedouble	encode number as eight-byte double precision float
# -----	encodelong		encode number as four-byte long

def encodestring(n)
  a,b=n.size.divmod(256)
  a.chr+b.chr+n
end

def encodedouble(n)
  [n].pack('G')
end

def encodelong(n)
  [n].pack('N')
end

# ====================================================================
# Co-ordinate conversion

def lat2coord(a,basey,masterscale)
  -(lat2y(a)-basey)*masterscale+250
end

def long2coord(a,baselong,masterscale)
  (a-baselong)*masterscale+350
end

def lat2y(a)
  180/Math::PI * Math.log(Math.tan(Math::PI/4+a*(Math::PI/180)/2))
end

def coord2lat(a,masterscale,basey)
  y2lat((a-250)/-masterscale+basey)
end

def coord2long(a,masterscale,baselong)
  (a-350)/masterscale+baselong
end

def y2lat(a)
  180/Math::PI * (2*Math.atan(Math.exp(a*Math::PI/180))-Math::PI/2)
end

end
