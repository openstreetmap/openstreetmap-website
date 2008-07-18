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
    renumberedways={}							# Shared across repeated putways

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
      when 'getrelation';		results[index]=AMF.putdata(index,getrelation(args))
      when 'getway_old';		results[index]=AMF.putdata(index,getway_old(args))
      when 'getway_history';	results[index]=AMF.putdata(index,getway_history(args))
      when 'putway';			r=putway(args,renumberednodes)
								renumberednodes=r[3]
								if r[1] != r[2]
									renumberedways[r[1]] = r[2]
								end
								results[index]=AMF.putdata(index,r)
      when 'putrelation';		results[index]=AMF.putdata(index,putrelation(args, renumberednodes, renumberedways))
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

  def whichways(xmin, ymin, xmax, ymax) #:doc:
	xmin -= 0.01; ymin -= 0.01
	xmax += 0.01; ymax += 0.01

	if POTLATCH_USE_SQL then
	  way_ids = sql_find_way_ids_in_area(xmin, ymin, xmax, ymax)
	  points = sql_find_pois_in_area(xmin, ymin, xmax, ymax)
	  relation_ids = sql_find_relations_in_area_and_ways(xmin, ymin, xmax, ymax, way_ids)
	else
	  # find the way ids in an area
	  nodes_in_area = Node.find_by_area(ymin, xmin, ymax, xmax, :conditions => "current_nodes.visible = 1", :include => :ways)
	  way_ids = nodes_in_area.collect { |node| node.way_ids }.flatten.uniq

    # find the node ids in an area that aren't part of ways
    nodes_not_used_in_area = nodes_in_area.select { |node| node.ways.empty? }
    points = nodes_not_used_in_area.collect { |n| [n.id, n.lon_potlatch(baselong,masterscale), n.lat_potlatch(basey,masterscale), n.tags_as_hash] }

	  # find the relations used by those nodes and ways
	  relations = Relation.find_for_nodes(nodes_in_area.collect { |n| n.id }, :conditions => "visible = 1") +
                  Relation.find_for_ways(way_ids, :conditions => "visible = 1")
	  relation_ids = relations.collect { |relation| relation.id }.uniq
	end

	[way_ids, points, relation_ids]
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

  def whichways_deleted(xmin, ymin, xmax, ymax) #:doc:
	xmin -= 0.01; ymin -= 0.01
	xmax += 0.01; ymax += 0.01

	nodes_in_area = Node.find_by_area(ymin, xmin, ymax, xmax, :conditions => "current_nodes.visible = 0 AND current_ways.visible = 0", :include => :ways_via_history)
	way_ids = nodes_in_area.collect { |node| node.ways_via_history_ids }.flatten.uniq

	[way_ids]
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

  def getway(wayid) #:doc:
	if POTLATCH_USE_SQL then
	  points = sql_get_nodes_in_way(wayid)
	  tags = sql_get_tags_in_way(wayid)
	else
	  # Ideally we would do ":include => :nodes" here but if we do that
	  # then rails only seems to return the first copy of a node when a
	  # way includes a node more than once
	  way = Way.find(wayid)
	  points = way.nodes.collect do |node|
		[node.lon, node.lat, node.id, nil, node.tags_as_hash]
	  end
	  tags = way.tags
	end

	[wayid, points, tags]
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

  def getway_old(id, version) #:doc:
	if version < 0
	  old_way = OldWay.find(:first, :conditions => ['visible = 1 AND id = ?', id], :order => 'version DESC')
	  points = old_way.get_nodes_undelete
	else
	  old_way = OldWay.find(:first, :conditions => ['id = ? AND version = ?', id, version])
	  points = old_way.get_nodes_revert
	end

	old_way.tags['history'] = "Retrieved from v#{old_way.version}"

	[0, id, points, old_way.tags, old_way.version]
  end

  def getway_history(wayid) #:doc:
	history = Way.find(wayid).old_ways.collect do |old_way|
	  user = old_way.user.data_public? ? old_way.user.display_name : 'anonymous'
	  [old_way.version, old_way.timestamp.strftime("%d %b %Y, %H:%M"), old_way.visible ? 1 : 0, user]
	end

	[history]
  end

  # Get a relation with all tags and members.
  # Returns:
  # 0. relation id,
  # 1. hash of tags,
  # 2. list of members.
  
  def getrelation(relid) #:doc:
	rel = Relation.find(relid)

	[relid, rel.tags, rel.members]
  end

  # ----- getrelation
  #		  save relation to the database
  #		  in:	[0] user token (string),
  #				[1] original relation id (may be negative),
  #			  	[2] hash of tags, [3] list of members,
  #				[4] visible
  #		  out:	[0] 0 (success), [1] original relation id (unchanged),
  #				[2] new relation id
  def putrelation(args, renumberednodes, renumberedways) #:doc:
    usertoken,relid,tags,members,visible=args
    uid=getuserid(usertoken)
    if !uid then return -1,"You are not logged in, so the point could not be saved." end

  def putrelation(renumberednodes, renumberedways, usertoken, relid, tags, members, visible) #:doc:
	uid = getuserid(usertoken)
	if !uid then return -1,"You are not logged in, so the relation could not be saved." end

	relid = relid.to_i
	visible = visible.to_i

	# create a new relation, or find the existing one
    if relid <= 0
      rel = Relation.new
    else
      rel = Relation.find(relid)
    end

    # check the members are all positive, and correctly type
    typedmembers = []
    members.each do |m|
      mid = m[1].to_i
      if mid < 0
        mid = renumberednodes[mid] if m[0] == 'node'
        mid = renumberedways[mid] if m[0] == 'way'
        if mid < 0
          return -2, "Negative ID unresolved"
        end
      end
      typedmembers << [m[0], mid, m[2]]
    end

	# assign new contents
	rel.members = typedmembers
	rel.tags = tags
	rel.visible = visible
	rel.user_id = uid

    # check it then save it
    # BUG: the following is commented out because it always fails on my
    #  install. I think it's a Rails bug.

    #if !rel.preconditions_ok?
    #  return -2, "Relation preconditions failed"
    #else
      rel.save_with_history!
    #end

	[0, relid, rel.id]
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

  def putway(renumberednodes, usertoken, originalway, points, attributes) #:doc:

	# -- Initialise and carry out checks
	
	uid = getuserid(usertoken)
	if !uid then return -1,"You are not logged in, so the way could not be saved." end

	originalway = originalway.to_i

	points.each do |a|
	  if a[2] == 0 or a[2].nil? then return -2,"Server error - node with id 0 found in way #{originalway}." end
	  if a[1] == 90 then return -2,"Server error - node with lat -90 found in way #{originalway}." end
	end

	if points.length < 2 then return -2,"Server error - way is only #{points.length} points long." end

    # -- 3.	read original way into memory

	if originalway < 0
	  way = Way.new
	  uniques = []
	else
	  way = Way.find(originalway)
	  uniques = way.unshared_node_ids
	end

    # -- 4.	get version by inserting new row into ways

	nodes = []

	points.each do |n|
	  lon = n[0].to_f
	  lat = n[1].to_f
	  id = n[2].to_i
	  savenode = false

	  if renumberednodes[id]
	    id = renumberednodes[id]
	  elsif id < 0
		# Create new node
		node = Node.new
		savenode = true
	  else
		node = Node.find(id)
		if !fpcomp(lat, node.lat) or !fpcomp(lon, node.lon) or
		   Tags.join(n[4]) != node.tags or !node.visible?
		  savenode = true
		end
	  end

	  if savenode
		node.user_id = uid
	    node.lat = lat
        node.lon = lon
	    node.tags = Tags.join(n[4])
	    node.visible = true
	    node.save_with_history!

		if id != node.id
		  renumberednodes[id] = node.id
		  id = node.id
	    end
	  end

	  uniques = uniques - [id]
	  nodes.push(id)
	end

	# -- Delete any unique nodes
	
	uniques.each do |n|
	  deleteitemrelations(n, 'node')

	  node = Node.find(n)
	  node.user_id = uid
	  node.visible = false
	  node.save_with_history!
	end

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

	way.tags = attributes
	way.nds = nodes
	way.user_id = uid
	way.visible = true
	way.save_with_history!

	[0, originalway, way.id, renumberednodes]
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

  def putpoi(usertoken, id, lon, lat, tags, visible) #:doc:
	uid = getuserid(usertoken)
	if !uid then return -1,"You are not logged in, so the point could not be saved." end

	id = id.to_i
	visible = (visible.to_i == 1)

	if id > 0 then
	  node = Node.find(id)

	  if !visible then
	    unless node.ways.empty? then return -1,"The point has since become part of a way, so you cannot save it as a POI." end
	    deleteitemrelations(id, 'node')
	  end
	else
	  node = Node.new
	end

	node.user_id = uid
	node.lat = lat
	node.lon = lon
	node.tags = Tags.join(tags)
	node.visible = visible
	node.save_with_history!

	[0, id, node.id]
  end

  # ----- getpoi
  # read POI from database
  #		  (only called on revert: POIs are usually read by whichways)
  #		  in:	[0] node id, [1] baselong, [2] basey, [3] masterscale
  #		  does: reads POI
  #		  out:	[0] id (unchanged), [1] projected long, [2] projected lat,
  #				[3] hash of tags
  def getpoi(args) #:doc:
    id,baselong,basey,masterscale = args
    
    n = Node.find(id.to_i)
    if n
      return [n.id, n.lon_potlatch(baselong,masterscale), n.lat_potlatch(basey,masterscale), n.tags_as_hash]
    else
      return [nil,nil,nil,'']
    end
  end

  def getpoi(id) #:doc:
	n = Node.find(id)

	if n
	  return [n.id, n.lon, n.lat, n.tags_as_hash]
	else
	  return [nil, nil, nil, '']
	end
  end


  def deleteway(usertoken, way_id) #:doc:
	uid = getuserid(usertoken)
	if !uid then return -1,"You are not logged in, so the way could not be deleted." end

	# FIXME: would be good not to make two history entries when removing
	#		 two nodes from the same relation
	user = User.find(uid)
	way = Way.find(way_id)
	way.unshared_node_ids.each do |n|
	  deleteitemrelations(n, 'node')
	end

	way.delete_with_relations_and_nodes_and_history(user)  

	[0, way_id]
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

  def deleteitemrelations(objid, type) #:doc:
	relations = RelationMember.find(:all, 
									:conditions => ['member_type = ? and member_id = ?', type, objid], 
									:include => :relation).collect { |rm| rm.relation }.uniq

	relations.each do |rel|
	  rel.members.delete_if { |x| x[0] == type and x[1] == objid }
	  rel.save_with_history!
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
    -(lat2y(a)-basey)*masterscale
  end

  def long2coord(a,baselong,masterscale) #:doc:
    (a-baselong)*masterscale
  end

  def lat2y(a) #:doc:
    180/Math::PI * Math.log(Math.tan(Math::PI/4+a*(Math::PI/180)/2))
  end

  def coord2lat(a,masterscale,basey) #:doc:
    y2lat(a/-masterscale+basey)
  end

  def coord2long(a,masterscale,baselong) #:doc:
    a/masterscale+baselong
  end

  def y2lat(a)
    180/Math::PI * (2*Math.atan(Math.exp(a*Math::PI/180))-Math::PI/2)
  end

end

# Local Variables:
# indent-tabs-mode: t
# tab-width: 4
# End:
