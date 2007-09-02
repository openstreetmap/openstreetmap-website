class AmfController < ApplicationController
  require 'stringio'

  session :off
  before_filter :check_availability

  # to log:
  # RAILS_DEFAULT_LOGGER.error("Args: #{args[0]}, #{args[1]}, #{args[2]}, #{args[3]}")

  # ====================================================================
  # Main AMF handler

  # ---- talk	process AMF request

  def talk
    req=StringIO.new(request.raw_post)	# Get POST data as request
    req.read(2)							# Skip version indicator and client ID
    results={}							# Results of each body

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
		  when 'getpresets';	results[index]=putdata(index,getpresets)
		  when 'whichways';		results[index]=putdata(index,whichways(args))
		  when 'getway';		results[index]=putdata(index,getway(args))
		  when 'putway';		results[index]=putdata(index,putway(args))
		  when 'deleteway';		results[index]=putdata(index,deleteway(args))
		  when 'makeway';		results[index]=putdata(index,makeway(args))
		  when 'putpoi';		results[index]=putdata(index,putpoi(args))
		  when 'getpoi';		results[index]=putdata(index,getpoi(args))
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
residential road: highway=residential,name=(type road name)
unclassified road: highway=unclassified,name=(type road name)

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

way/railway
railway: railway=rail
tramway: railway=tram
light railway: railway=light_rail
preserved railway: railway=preserved
disused railway tracks: railway=disused
course of old railway: railway=abandoned

way/natural
lake: landuse=water
forest: landuse=forest

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
peak: point=peak

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
peak: point=peak
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
    return [presets,presetmenus,presetnames]
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

    waylist=WaySegment.find_by_sql("SELECT DISTINCT current_way_segments.id AS wayid"+
       "  FROM current_way_segments,current_segments,current_nodes,current_ways "+
       " WHERE segment_id=current_segments.id "+
       "   AND current_segments.visible=1 "+
       "   AND node_a=current_nodes.id "+
	   "   AND current_ways.id=current_way_segments.id "+
	   "   AND current_ways.visible=1 "+
       "   AND (latitude  BETWEEN "+ymin.to_s+" AND "+ymax.to_s+") "+
       "   AND (longitude BETWEEN "+xmin.to_s+" AND "+xmax.to_s+")")

       ways = waylist.collect {|a| a.wayid.to_i } # get an array of way id's

       pointlist =ActiveRecord::Base.connection.select_all("SELECT current_nodes.id,latitude,longitude,current_nodes.tags "+
       "  FROM current_nodes "+
       "  LEFT OUTER JOIN current_segments cs1 ON cs1.node_a=current_nodes.id "+
       "  LEFT OUTER JOIN current_segments cs2 ON cs2.node_b=current_nodes.id "+
       " WHERE (latitude  BETWEEN "+ymin.to_s+" AND "+ymax.to_s+") "+
       "   AND (longitude BETWEEN "+xmin.to_s+" AND "+xmax.to_s+") "+
       "   AND cs1.id IS NULL AND cs2.id IS NULL "+
       "   AND current_nodes.visible=1")

	    points = pointlist.collect {|a| [a['id'],long2coord(a['longitude'].to_f,baselong,masterscale),lat2coord(a['latitude'].to_f,basey,masterscale),tag2array(a['tags'])]	} # get a list of node ids and their tags

    return [ways,points]
  end

  # ----- getway (objectname, way, baselong, basey, masterscale)
  #		  returns objectname, array of co-ordinates, attributes,
  #				  xmin,xmax,ymin,ymax

  def getway(args)
    objname,wayid,baselong,basey,masterscale=args
    wayid = wayid.to_i
    points = []
    lastid = -1
    xmin = ymin = 999999
    xmax = ymax = -999999

    RAILS_DEFAULT_LOGGER.info("  Message: getway, id=#{wayid}")

    readwayquery(wayid).each {|row|
      xs1=long2coord(row['long1'].to_f,baselong,masterscale); ys1=lat2coord(row['lat1'].to_f,basey,masterscale)
      xs2=long2coord(row['long2'].to_f,baselong,masterscale); ys2=lat2coord(row['lat2'].to_f,basey,masterscale)
      points << [xs1,ys1,row['id1'].to_i,0,tag2array(row['tags1']),0] if (row['id1'].to_i!=lastid)
      lastid = row['id2'].to_i
      points << [xs2,ys2,row['id2'].to_i,1,tag2array(row['tags2']),row['segment_id'].to_i]
      xmin = [xmin,row['long1'].to_f,row['long2'].to_f].min
      xmax = [xmax,row['long1'].to_f,row['long2'].to_f].max
      ymin = [ymin,row['lat1'].to_f,row['lat2'].to_f].min
      ymax = [ymax,row['lat1'].to_f,row['lat2'].to_f].max
    }

    attributes={}
    attrlist=ActiveRecord::Base.connection.select_all "SELECT k,v FROM current_way_tags WHERE id=#{wayid}"
    attrlist.each {|a| attributes[a['k']]=a['v'] }

    [objname,points,attributes,xmin,xmax,ymin,ymax]
  end

  # -----	putway (user token, way, array of co-ordinates, array of attributes,
  #					baselong, basey, masterscale)
  #			returns current way ID, new way ID, hash of renumbered nodes,
  #					xmin,xmax,ymin,ymax

  def putway(args)
    usertoken,originalway,points,attributes,baselong,basey,masterscale=args
    uid=getuserid(usertoken)
    return if !uid
    db_uqs='uniq'+uid.to_s+originalway.to_i.abs.to_s+Time.new.to_i.to_s	# temp uniquesegments table name, typically 51 chars
    db_uqn='unin'+uid.to_s+originalway.to_i.abs.to_s+Time.new.to_i.to_s	# temp uniquenodes table name, typically 51 chars
    db_now='@now'+uid.to_s+originalway.to_i.abs.to_s+Time.new.to_i.to_s	# 'now' variable name, typically 51 chars
    ActiveRecord::Base.connection.execute("SET #{db_now}=NOW()")
    originalway=originalway.to_i

    RAILS_DEFAULT_LOGGER.info("  Message: putway, id=#{originalway}")

    # -- 3.	read original way into memory

    xc={}; yc={}; tagc={}; seg={}
    if originalway>0
      way=originalway
      readwayquery(way).each { |row|
        id1=row['id1'].to_i; xc[id1]=row['long1'].to_f; yc[id1]=row['lat1'].to_f; tagc[id1]=row['tags1']
        id2=row['id2'].to_i; xc[id2]=row['long2'].to_f; yc[id2]=row['lat2'].to_f; tagc[id2]=row['tags2']
        seg[row['segment_id'].to_i]=id1.to_s+'-'+id2.to_s
      }
	  ActiveRecord::Base.connection.update("UPDATE current_ways SET timestamp=#{db_now},user_id=#{uid},visible=1 WHERE id=#{way}")
    else
      way=ActiveRecord::Base.connection.insert("INSERT INTO current_ways (user_id,timestamp,visible) VALUES (#{uid},#{db_now},1)")
    end

    # -- 4.	get version by inserting new row into ways

    version=ActiveRecord::Base.connection.insert("INSERT INTO ways (id,user_id,timestamp,visible) VALUES (#{way},#{uid},#{db_now},1)")

    # -- 5. compare nodes and update xmin,xmax,ymin,ymax

    xmin = ymin = 999999
    xmax = ymax = -999999
    insertsql = ''
    renumberednodes={}

    points.each_index do |i|
      xs=coord2long(points[i][0],masterscale,baselong)
      ys=coord2lat(points[i][1],masterscale,basey)
      xmin=[xs,xmin].min; xmax=[xs,xmax].max
      ymin=[ys,ymin].min; ymax=[ys,ymax].max
      node=points[i][2].to_i
      tagstr=array2tag(points[i][4])
	  tagstr=tagstr.gsub(/[\000-\037]/,"")
      tagsql="'"+sqlescape(tagstr)+"'"

      # compare node
      if node<0
        # new node - create
		if renumberednodes[node.to_s].nil?
			newnode=ActiveRecord::Base.connection.insert("INSERT INTO current_nodes (   latitude,longitude,timestamp,user_id,visible,tags) VALUES (           #{ys},#{xs},#{db_now},#{uid},1,#{tagsql})")
					ActiveRecord::Base.connection.insert("INSERT INTO nodes         (id,latitude,longitude,timestamp,user_id,visible,tags) VALUES (#{newnode},#{ys},#{xs},#{db_now},#{uid},1,#{tagsql})")
			points[i][2]=newnode
			renumberednodes[node.to_s]=newnode.to_s
		else
			points[i][2]=renumberednodes[node.to_s].to_i
		end

      elsif xc.has_key?(node)
        # old node from original way - update
        if (xs!=xc[node] or (ys/0.0000001).round!=(yc[node]/0.0000001).round or tagstr!=tagc[node])
          ActiveRecord::Base.connection.insert("INSERT INTO nodes (id,latitude,longitude,timestamp,user_id,visible,tags) VALUES (#{node},#{ys},#{xs},#{db_now},#{uid},1,#{tagsql})")
          ActiveRecord::Base.connection.update("UPDATE current_nodes SET latitude=#{ys},longitude=#{xs},timestamp=#{db_now},user_id=#{uid},tags=#{tagsql},visible=1 WHERE id=#{node}")
        end
      else
        # old node, created in another way and now added to this way
      end

    end


    # -- 6.i compare segments

    numberedsegments={}
    seglist=''				# list of existing segments that we want to keep
    for i in (0..(points.length-2))
      if (points[i+1][3].to_i==0) then next end
      segid=points[i+1][5].to_i
      from =points[i  ][2].to_i
      to   =points[i+1][2].to_i
      if seg.has_key?(segid)
		# if segment exists, check it still refers to the same nodes
        if seg[segid]=="#{from}-#{to}" then 
          if (seglist!='') then seglist+=',' end; seglist+=segid.to_s
          next
        end
	  elsif segid>0
		# not in previous version of way, but supplied, so assume
		# that it's come from makeway (i.e. unwayed segments)
		if (seglist!='') then seglist+=',' end; seglist+=segid.to_s
		next
      end
      segid=ActiveRecord::Base.connection.insert("INSERT INTO current_segments (   node_a,node_b,timestamp,user_id,visible,tags) VALUES (         #{from},#{to},#{db_now},#{uid},1,'')")
      		ActiveRecord::Base.connection.insert("INSERT INTO segments         (id,node_a,node_b,timestamp,user_id,visible,tags) VALUES (#{segid},#{from},#{to},#{db_now},#{uid},1,'')")
      points[i+1][5]=segid
      numberedsegments[(i+1).to_s]=segid.to_s
    end


    # -- 6.ii insert new way segments

    createuniquesegments(way,db_uqs,seglist)	# segments which appear in this way but no other

    #		delete segments from uniquesegments (and not in modified way)

    sql=<<-EOF
      INSERT INTO segments (id,node_a,node_b,timestamp,user_id,visible) 
      SELECT DISTINCT segment_id,node_a,node_b,#{db_now},#{uid},0
        FROM current_segments AS cs, #{db_uqs} AS us
       WHERE cs.id=us.segment_id AND cs.visible=1 
    EOF
    ActiveRecord::Base.connection.insert(sql)

    sql=<<-EOF
         UPDATE current_segments AS cs, #{db_uqs} AS us
          SET cs.timestamp=#{db_now},cs.visible=0,cs.user_id=#{uid} 
        WHERE cs.id=us.segment_id AND cs.visible=1 
    EOF
    ActiveRecord::Base.connection.update(sql)

    #		delete nodes not in modified way or any other segments

    createuniquenodes(db_uqs,db_uqn)	# nodes which appear in this way but no other

    sql=<<-EOF
		INSERT INTO nodes (id,latitude,longitude,timestamp,user_id,visible)  
		SELECT DISTINCT cn.id,cn.latitude,cn.longitude,#{db_now},#{uid},0 
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

    ActiveRecord::Base.connection.execute("DROP TABLE #{db_uqs}")
    ActiveRecord::Base.connection.execute("DROP TABLE #{db_uqn}")

    #		insert new version of route into way_segments

    insertsql =''
    currentsql=''
    sequence  =1
    for i in (0..(points.length-2))
      if (points[i+1][3].to_i==0) then next end
      if insertsql !='' then insertsql +=',' end
      if currentsql!='' then currentsql+=',' end
      insertsql +="(#{way},#{points[i+1][5]},#{version})"
      currentsql+="(#{way},#{points[i+1][5]},#{sequence})"
      sequence  +=1
    end

    ActiveRecord::Base.connection.execute("DELETE FROM current_way_segments WHERE id=#{way}");
    ActiveRecord::Base.connection.insert("INSERT INTO         way_segments (id,segment_id,version    ) VALUES #{insertsql}");
    ActiveRecord::Base.connection.insert("INSERT INTO current_way_segments (id,segment_id,sequence_id) VALUES #{currentsql}");

    # -- 7. insert new way tags

    insertsql =''
    currentsql=''
    attributes.each do |k,v|
      if v=='' or v.nil? then next end
      if v[0,6]=='(type ' then next end
      if insertsql !='' then insertsql +=',' end
      if currentsql!='' then currentsql+=',' end
	  k=k.gsub(/[\000-\037]/,"")
	  v=v.gsub(/[\000-\037]/,"")
      insertsql +="(#{way},'"+sqlescape(k)+"','"+sqlescape(v)+"',#{version})"
      currentsql+="(#{way},'"+sqlescape(k)+"','"+sqlescape(v)+"')"
    end

    ActiveRecord::Base.connection.execute("DELETE FROM current_way_tags WHERE id=#{way}")
    if (insertsql !='') then ActiveRecord::Base.connection.insert("INSERT INTO way_tags (id,k,v,version) VALUES #{insertsql}" ) end
    if (currentsql!='') then ActiveRecord::Base.connection.insert("INSERT INTO current_way_tags (id,k,v) VALUES #{currentsql}") end

    [originalway,way,renumberednodes,numberedsegments,xmin,xmax,ymin,ymax]
  end

  # -----	putpoi (user token, id, x,y,tag array,visible,baselong,basey,masterscale)
  #			returns current id, new id
  #			if new: add new row to current_nodes and nodes
  #			if old: add new row to nodes, update current_nodes

  def putpoi(args)
	usertoken,id,x,y,tags,visible,baselong,basey,masterscale=args
	uid=getuserid(usertoken)
	return if !uid
    db_now='@now'+uid.to_s+id.to_i.abs.to_s+Time.new.to_i.to_s	# 'now' variable name, typically 51 chars
    ActiveRecord::Base.connection.execute("SET #{db_now}=NOW()")

	id=id.to_i
	visible=visible.to_i
	x=coord2long(x.to_f,masterscale,baselong)
	y=coord2lat(y.to_f,masterscale,basey)
	tagsql="'"+sqlescape(array2tag(tags))+"'"
	
	if (id>0) then
		ActiveRecord::Base.connection.insert("INSERT INTO nodes (id,latitude,longitude,timestamp,user_id,visible,tags) VALUES (#{id},#{y},#{x},#{db_now},#{uid},#{visible},#{tagsql})");
		ActiveRecord::Base.connection.update("UPDATE current_nodes SET latitude=#{y},longitude=#{x},timestamp=#{db_now},user_id=#{uid},visible=#{visible},tags=#{tagsql} WHERE id=#{id}");
		newid=id
	else
		newid=ActiveRecord::Base.connection.insert("INSERT INTO current_nodes (latitude,longitude,timestamp,user_id,visible,tags) VALUES (#{y},#{x},#{db_now},#{uid},#{visible},#{tagsql})");
			  ActiveRecord::Base.connection.update("INSERT INTO nodes (id,latitude,longitude,timestamp,user_id,visible,tags) VALUES (#{newid},#{y},#{x},#{db_now},#{uid},#{visible},#{tagsql})");
	end
	[id,newid]
  end

  # -----	getpoi (id,baselong,basey,masterscale)
  #			returns id,x,y,tag array
  
  def getpoi(args)
	id,baselong,basey,masterscale=args; id=id.to_i
	poi=ActiveRecord::Base.connection.select_one("SELECT latitude,longitude,tags "+
		"FROM current_nodes WHERE visible=1 AND id=#{id}")
	if poi.nil? then return [nil,nil,nil,''] end
	[id,
	 long2coord(poi['longitude'].to_f,baselong,masterscale),
	 lat2coord(poi['latitude'].to_f,basey,masterscale),
	 tag2array(poi['tags'])]
  end

  # -----	deleteway (user token, way)
  #			returns way ID only

  def deleteway(args)
    usertoken,way=args

    RAILS_DEFAULT_LOGGER.info("  Message: deleteway, id=#{way}")

    uid=getuserid(usertoken); if !uid then return end
	way=way.to_i

	db_uqs='uniq'+uid.to_s+way.to_i.abs.to_s+Time.new.to_i.to_s	# temp uniquesegments table name, typically 51 chars
	db_uqn='unin'+uid.to_s+way.to_i.abs.to_s+Time.new.to_i.to_s	# temp uniquenodes table name, typically 51 chars
	db_now='@now'+uid.to_s+way.to_i.abs.to_s+Time.new.to_i.to_s	# 'now' variable name, typically 51 chars
	ActiveRecord::Base.connection.execute("SET #{db_now}=NOW()")
	createuniquesegments(way,db_uqs,'')

	# -	delete any otherwise unused segments

	sql=<<-EOF
      INSERT INTO segments (id,node_a,node_b,timestamp,user_id,visible) 
      SELECT DISTINCT segment_id,node_a,node_b,#{db_now},#{uid},0 
        FROM current_segments AS cs, #{db_uqs} AS us
       WHERE cs.id=us.segment_id
    EOF
	ActiveRecord::Base.connection.insert(sql)

	sql=<<-EOF
      UPDATE current_segments AS cs, #{db_uqs} AS us
         SET cs.timestamp=#{db_now},cs.visible=0,cs.user_id=#{uid} 
       WHERE cs.id=us.segment_id
    EOF
	ActiveRecord::Base.connection.update(sql)

	# - delete any unused nodes
  
    createuniquenodes(db_uqs,db_uqn)

	sql=<<-EOF
		INSERT INTO nodes (id,latitude,longitude,timestamp,user_id,visible)  
		SELECT DISTINCT cn.id,cn.latitude,cn.longitude,#{db_now},#{uid},0 
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
	
	ActiveRecord::Base.connection.execute("DROP TABLE #{db_uqs}")
	ActiveRecord::Base.connection.execute("DROP TABLE #{db_uqn}")

	# - delete way
	
	ActiveRecord::Base.connection.insert("INSERT INTO ways (id,user_id,timestamp,visible) VALUES (#{way},#{uid},#{db_now},0)")
	ActiveRecord::Base.connection.update("UPDATE current_ways SET user_id=#{uid},timestamp=#{db_now},visible=0 WHERE id=#{way}")
	ActiveRecord::Base.connection.execute("DELETE FROM current_way_segments WHERE id=#{way}")
	ActiveRecord::Base.connection.execute("DELETE FROM current_way_tags WHERE id=#{way}")
	
	way
end

# ----- makeway(x,y,baselong,basey,masterscale)
#		returns way made from unwayed segments

def makeway(args)
	usertoken,x,y,baselong,basey,masterscale=args
    uid=getuserid(usertoken)
    return if !uid

	points=[]
	toreverse=[]				# segments to reverse
	nodesused={}				# so we don't go over the same node twice

	# - find start point near x
	
	xc=coord2long(x,masterscale,baselong)
	yc=coord2lat(y,masterscale,basey)

        RAILS_DEFAULT_LOGGER.info("  Message: makeway, xc=#{xc}, y=#{yc}")

	xs1=xc-0.001; xs2=xc+0.001
	ys1=yc-0.001; ys2=yc+0.001
	
	sql=<<-EOF
		SELECT cn1.latitude AS lat1,cn1.longitude AS lon1,cn1.id AS id1,
		       cn2.latitude AS lat2,cn2.longitude AS lon2,cn2.id AS id2, cs.id AS segid
		  FROM current_nodes AS cn1,
		       current_nodes AS cn2,
		       current_segments AS cs 
		       LEFT OUTER JOIN current_way_segments ON segment_id=cs.id 
		 WHERE (cn1.longitude BETWEEN #{xs1} AND #{xs2}) 
		   AND (cn1.latitude  BETWEEN #{ys1} AND #{ys2}) 
		   AND segment_id IS NULL 
                   AND cs.visible=1
		   AND cn1.id=node_a AND cn1.visible=1 
		   AND cn2.id=node_b AND cn2.visible=1 
	      ORDER BY SQRT(POW(cn1.longitude-#{xc},2)+
      				POW(cn1.latitude -#{yc},2)) 
      	 LIMIT 1
	EOF
	row=ActiveRecord::Base.connection.select_one sql
	if row.nil? then return [0,0,0,0,0] end
	xs1=long2coord(row['lon1'].to_f,baselong,masterscale); ys1=lat2coord(row['lat1'].to_f,basey,masterscale)
	xs2=long2coord(row['lon2'].to_f,baselong,masterscale); ys2=lat2coord(row['lat2'].to_f,basey,masterscale)
	xmin=[xs1,xs2].min; xmax=[xs1,xs2].max
	ymin=[ys1,ys2].min; ymax=[ys1,ys2].max
	nodesused[row['id1'].to_i]=true
	nodesused[row['id2'].to_i]=true
	points<<[xs1,ys1,row['id1'].to_i,1,{},0]
	points<<[xs2,ys2,row['id2'].to_i,1,{},row['segid'].to_i]
	
	# - extend at start, then end
	while (a,point,nodesused,toreverse=findconnect(points[0][2],nodesused,'b',toreverse,baselong,basey,masterscale))[0]
		points[0][5]=point[5]; point[5]=0	# segment leads to next node
		points.unshift(point)
		xmin=[point[0],xmin].min; xmax=[point[0],xmax].max
		ymin=[point[1],ymin].min; ymax=[point[1],ymax].max
	end
	while (a,point,nodesused,toreverse=findconnect(points[-1][2],nodesused,'a',toreverse,baselong,basey,masterscale))[0]
		points.push(point)
		xmin=[point[0],xmin].min; xmax=[point[0],xmax].max
		ymin=[point[1],ymin].min; ymax=[point[1],ymax].max
	end
	points[0][3]=0	# start with a move

	# reverse segments in toreverse
	if toreverse.length>0
		sql=<<-EOF
			UPDATE current_segments c1, current_segments c2 
			   SET c1.node_a=c2.node_b,c1.node_b=c2.node_a,
			       c1.timestamp=NOW(),c1.user_id=#{uid} 
			 WHERE c1.id=c2.id 
			   AND c1.id IN (#{toreverse.join(',')})
		EOF
		ActiveRecord::Base.connection.update sql
		sql=<<-EOF
			INSERT INTO segments 
		   (SELECT * FROM current_segments 
		     WHERE id IN (#{toreverse.join(',')}))
		EOF
		ActiveRecord::Base.connection.insert sql
	end

	[points,xmin,xmax,ymin,ymax]
end

def findconnect(id,nodesused,lookfor,toreverse,baselong,basey,masterscale)
	# get all segments with 'id' as a point
	# (to look for both node_a and node_b, UNION is faster than node_a=id OR node_b=id)!
	sql=<<-EOF
		SELECT cn1.latitude AS lat1,cn1.longitude AS lon1,cn1.id AS id1,
		       cn2.latitude AS lat2,cn2.longitude AS lon2,cn2.id AS id2, cs.id AS segid
		  FROM current_nodes AS cn1,
		       current_nodes AS cn2,
		       current_segments AS cs 
		       LEFT OUTER JOIN current_way_segments ON segment_id=cs.id 
		 WHERE segment_id IS NULL 
                   AND cs.visible=1
		   AND cn1.id=node_a AND cn1.visible=1 
		   AND cn2.id=node_b AND cn2.visible=1 
		   AND node_a=#{id}
	UNION
		SELECT cn1.latitude AS lat1,cn1.longitude AS lon1,cn1.id AS id1,
		       cn2.latitude AS lat2,cn2.longitude AS lon2,cn2.id AS id2, cs.id AS segid
		  FROM current_nodes AS cn1,
		       current_nodes AS cn2,
		       current_segments AS cs 
		       LEFT OUTER JOIN current_way_segments ON segment_id=cs.id 
		 WHERE segment_id IS NULL 
                   AND cs.visible=1
		   AND cn1.id=node_a AND cn1.visible=1 
		   AND cn2.id=node_b AND cn2.visible=1 
		   AND node_b=#{id}
	EOF
	connectlist=ActiveRecord::Base.connection.select_all sql
	
	if lookfor=='b' then tocol='id1'; tolat='lat1'; tolon='lon1'; fromcol='id2'; fromlat='lat2'; fromlon='lon2'
					else tocol='id2'; tolat='lat2'; tolon='lon2'; fromcol='id1'; fromlat='lat1'; fromlon='lon1'
	end
	
	# eliminate those already in the hash
	connex=0
	point=nil
	connectlist.each { |row|
		tonode=row[tocol].to_i
		fromnode=row[fromcol].to_i
		if id==tonode and !nodesused.has_key?(fromnode)
			# wrong way round; add, then add to 'segments to reverse' list
			connex+=1
			nodesused[fromnode]=true
			point=[long2coord(row[fromlon].to_f,baselong,masterscale),lat2coord(row[fromlat].to_f,basey,masterscale),fromnode,1,{},row['segid'].to_i]
			toreverse.push(row['segid'].to_i)
		elsif id==fromnode and !nodesused.has_key?(tonode)
			# right way round; just add
			connex+=1
			point=[long2coord(row[tolon].to_f,baselong,masterscale),lat2coord(row[tolat].to_f,basey,masterscale),tonode,1,{},row['segid'].to_i]
			nodesused[tonode]=true
		end
	}
	
	# if only one left, then add it; otherwise return false
	if connex!=1 or point.nil? then
		return [false,[],nodesused,toreverse]
	else
		return [true,point,nodesused,toreverse]
	end
end


# ====================================================================
# Support functions for remote calls

def readwayquery(id)
  ActiveRecord::Base.connection.select_all "SELECT n1.latitude AS lat1,n1.longitude AS long1,n1.id AS id1,n1.tags as tags1, "+
      "		  n2.latitude AS lat2,n2.longitude AS long2,n2.id AS id2,n2.tags as tags2,segment_id "+
      "    FROM current_way_segments,current_segments,current_nodes AS n1,current_nodes AS n2 "+
      "   WHERE current_way_segments.id=#{id} "+
      "     AND segment_id=current_segments.id "+
	  "     AND current_segments.visible=1 "+
      "     AND n1.id=node_a and n2.id=node_b "+
      "     AND n1.visible=1 AND n2.visible=1 "+
      "   ORDER BY sequence_id"
end

def createuniquesegments(way,uqs_name,seglist)
  # Finds segments which appear in (previous version of) this way and no other
  sql=<<-EOF
      CREATE TEMPORARY TABLE #{uqs_name}
              SELECT a.segment_id
                FROM (SELECT DISTINCT segment_id FROM current_way_segments 
                  WHERE id = #{way}) a
             LEFT JOIN current_way_segments b 
                ON b.segment_id = a.segment_id
                 AND b.id != #{way}
               WHERE b.segment_id IS NULL
    EOF
  if (seglist!='') then sql+=" AND a.segment_id NOT IN (#{seglist})" end
  ActiveRecord::Base.connection.execute(sql)
end

def createuniquenodes(uqs_name,uqn_name)
	# Finds nodes which appear in uniquesegments but no other segments
	sql=<<-EOF
	CREATE TEMPORARY TABLE #{uqn_name}
	   SELECT DISTINCT node_id
	   FROM (SELECT cn.id AS node_id
	         FROM current_nodes AS cn,
  	              current_segments AS cs,
	              #{uqs_name} AS us
	         WHERE cs.id=us.segment_id
	           AND cn.id=cs.node_a) AS n
	   LEFT JOIN current_segments AS cs2 ON node_id=cs2.node_a AND cs2.visible=1
	   LEFT JOIN current_segments AS cs3 ON node_id=cs3.node_b AND cs3.visible=1
	   WHERE cs2.node_a IS NULL
	     AND cs3.node_b IS NULL
	EOF
	ActiveRecord::Base.connection.execute(sql)
	sql=<<-EOF
	INSERT INTO #{uqn_name}
	   SELECT DISTINCT node_id
	   FROM (SELECT cn.id AS node_id
	         FROM current_nodes AS cn,
  	              current_segments AS cs,
	              #{uqs_name} AS us
	         WHERE cs.id=us.segment_id
	           AND cn.id=cs.node_b) AS n
	   LEFT JOIN current_segments AS cs2 ON node_id=cs2.node_a AND cs2.visible=1
	   LEFT JOIN current_segments AS cs3 ON node_id=cs3.node_b AND cs3.visible=1
	   WHERE cs2.node_a IS NULL
	     AND cs3.node_b IS NULL
	EOF
	ActiveRecord::Base.connection.execute(sql)
end

def sqlescape(a)
  a.gsub("'","''").gsub(92.chr,92.chr+92.chr)
end

def tag2array(a)
  tags={}
  a.gsub(';;;','#%').split(';').each do |b|
    b.gsub!('#%',';;;')
    b.gsub!('===','#%')
    k,v=b.split('=')
    if k.nil? then k='' end
    if v.nil? then v='' end
    tags[k.gsub('#%','=')]=v.gsub('#%','=')
  end
  tags
end

def array2tag(a)
  str=''
  a.each do |k,v|
    if v=='' then next end
    if v[0,6]=='(type ' then next end
    if str!='' then str+=';' end
    str+=k.gsub(';',';;;').gsub('=','===')+'='+v.gsub(';',';;;').gsub('=','===')
  end
  str
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
  when 10;	return getarray(s)			# array
  else;		return nil					# error
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
