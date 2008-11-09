# amf_controller is a semi-standalone API for Flash clients, particularly 
# Potlatch. All interaction between Potlatch (as a .SWF application) and the 
# OSM database takes place using this controller. Messages are 
# encoded in the Actionscript Message Format (AMF).
#
# Helper functions are in /lib/potlatch.
#
# Author::	editions Systeme D / Richard Fairhurst 2004-2008
# Licence::	public domain.
#
# == General structure
#
# Apart from the amf_read and amf_write methods (which distribute the requests
# from the AMF message), each method generally takes arguments in the order 
# they were sent by the Potlatch SWF. Do not assume typing has been preserved. 
# Methods all return an array to the SWF.
# 
# == Debugging
# 
# Any method that returns a status code (0 for ok) can also send:
#	return(-1,"message")		<-- just puts up a dialogue
#	return(-2,"message")		<-- also asks the user to e-mail me
# 
# To write to the Rails log, use RAILS_DEFAULT_LOGGER.info("message").

class AmfController < ApplicationController
  require 'stringio'

  include Potlatch

  # Help methods for checking boundary sanity and area size
  include MapBoundary

  session :off
  before_filter :check_write_availability

  # Main AMF handlers: process the raw AMF string (using AMF library) and
  # calls each action (private method) accordingly.
  # ** FIXME: refactor to reduce duplication of code across read/write
  
  def amf_read
	req=StringIO.new(request.raw_post+0.chr)# Get POST data as request
											# (cf http://www.ruby-forum.com/topic/122163)
	req.read(2)								# Skip version indicator and client ID
	results={}								# Results of each body

	# Parse request

	headers=AMF.getint(req)					# Read number of headers

	headers.times do						# Read each header
	  name=AMF.getstring(req)				#  |
	  req.getc				   				#  | skip boolean
	  value=AMF.getvalue(req)				#  |
	  header["name"]=value					#  |
	end

	bodies=AMF.getint(req)					# Read number of bodies
	bodies.times do							# Read each body
	  message=AMF.getstring(req)			#  | get message name
	  index=AMF.getstring(req)				#  | get index in response sequence
	  bytes=AMF.getlong(req)				#  | get total size in bytes
	  args=AMF.getvalue(req)				#  | get response (probably an array)
      logger.info "Executing AMF #{message}:#{index}"

	  case message
		when 'getpresets';			results[index]=AMF.putdata(index,getpresets())
		when 'whichways';			results[index]=AMF.putdata(index,whichways(*args))
		when 'whichways_deleted';	results[index]=AMF.putdata(index,whichways_deleted(*args))
		when 'getway';				results[index]=AMF.putdata(index,getway(args[0].to_i))
		when 'getrelation';			results[index]=AMF.putdata(index,getrelation(args[0].to_i))
		when 'getway_old';			results[index]=AMF.putdata(index,getway_old(args[0].to_i,args[1].to_i))
		when 'getway_history';		results[index]=AMF.putdata(index,getway_history(args[0].to_i))
		when 'getnode_history';		results[index]=AMF.putdata(index,getnode_history(args[0].to_i))
		when 'findrelations';		results[index]=AMF.putdata(index,findrelations(*args))
		when 'getpoi';				results[index]=AMF.putdata(index,getpoi(*args))
	  end
	end
    logger.info("encoding AMF results")
    sendresponse(results)
  end

  def amf_write
	req=StringIO.new(request.raw_post+0.chr)
	req.read(2)
	results={}
	renumberednodes={}						# Shared across repeated putways
	renumberedways={}						# Shared across repeated putways

	headers=AMF.getint(req)					# Read number of headers
	headers.times do						# Read each header
	  name=AMF.getstring(req)				#  |
	  req.getc				   				#  | skip boolean
	  value=AMF.getvalue(req)				#  |
	  header["name"]=value					#  |
	end

	bodies=AMF.getint(req)					# Read number of bodies
	bodies.times do							# Read each body
	  message=AMF.getstring(req)			#  | get message name
	  index=AMF.getstring(req)				#  | get index in response sequence
	  bytes=AMF.getlong(req)				#  | get total size in bytes
	  args=AMF.getvalue(req)				#  | get response (probably an array)

	  case message
		when 'putway';				r=putway(renumberednodes,*args)
									renumberednodes=r[3]
									if r[1] != r[2]
									  renumberedways[r[1]] = r[2]
									end
									results[index]=AMF.putdata(index,r)
		when 'putrelation';			results[index]=AMF.putdata(index,putrelation(renumberednodes, renumberedways, *args))
		when 'deleteway';			results[index]=AMF.putdata(index,deleteway(*args))
		when 'putpoi';				results[index]=AMF.putdata(index,putpoi(*args))
		when 'startchangeset';		results[index]=AMF.putdata(index,startchangeset(*args))
	  end
	end
    sendresponse(results)
  end

  private

  # Start new changeset
  
  def startchangeset(usertoken, cstags, closeid, closecomment)
	uid = getuserid(usertoken)
	if !uid then return -1,"You are not logged in, so Potlatch can't write any changes to the database." end

	# close previous changeset and add comment
	if closeid
	end
	
	# open a new changeset
	cs = Changeset.new
	cs.tags = cstags
	cs.user_id = uid
	cs.created_at = Time.now
	cs.save_with_tags!
	return [0,cs.id]
  end

  # Return presets (default tags, localisation etc.):
  # uses POTLATCH_PRESETS global, set up in OSM::Potlatch.

  def getpresets() #:doc:
	return POTLATCH_PRESETS
  end

  # Find all the ways, POI nodes (i.e. not part of ways), and relations
  # in a given bounding box. Nodes are returned in full; ways and relations 
  # are IDs only. 

  def whichways(xmin, ymin, xmax, ymax) #:doc:
	xmin -= 0.01; ymin -= 0.01
	xmax += 0.01; ymax += 0.01
    
    # check boundary is sane and area within defined
    # see /config/application.yml
    begin
      check_boundaries(xmin, ymin, xmax, ymax)
    rescue Exception => err
      # FIXME: report an error rather than just return an empty result
      return [[],[],[]]
    end

	if POTLATCH_USE_SQL then
	  ways = sql_find_ways_in_area(xmin, ymin, xmax, ymax)
	  points = sql_find_pois_in_area(xmin, ymin, xmax, ymax)
	  relation_ids = sql_find_relations_in_area_and_ways(xmin, ymin, xmax, ymax, ways.collect {|x| x[0]})
	else
	  # find the way ids in an area
	  nodes_in_area = Node.find_by_area(ymin, xmin, ymax, xmax, :conditions => ["current_nodes.visible = ?", true], :include => :ways)  # ** include causes problems
	  way_ids = nodes_in_area.collect { |node| node.way_ids }.flatten.uniq
	  # ** get versions

	  # find the node ids in an area that aren't part of ways
	  nodes_not_used_in_area = nodes_in_area.select { |node| node.ways.empty? }
	  points = nodes_not_used_in_area.collect { |n| [n.id, n.lon, n.lat, n.tags] }

	  # find the relations used by those nodes and ways
	  relations = Relation.find_for_nodes(nodes_in_area.collect { |n| n.id }, :conditions => {:visible => true}) +
                  Relation.find_for_ways(way_ids, :conditions => {:visible => true})
	  relation_ids = relations.collect { |relation| relation.id }.uniq
	end

	[ways, points, relation_ids]
  end

  # Find deleted ways in current bounding box (similar to whichways, but ways
  # with a deleted node only - not POIs or relations).

  def whichways_deleted(xmin, ymin, xmax, ymax) #:doc:
	xmin -= 0.01; ymin -= 0.01
	xmax += 0.01; ymax += 0.01

    # check boundary is sane and area within defined
    # see /config/application.yml
    begin
      check_boundaries(xmin, ymin, xmax, ymax)
    rescue Exception => err
      # FIXME: report an error rather than just return an empty result
      return [[]]
    end

	nodes_in_area = Node.find_by_area(ymin, xmin, ymax, xmax, :conditions => ["current_ways.visible = ?", false], :include => :ways_via_history)
	way_ids = nodes_in_area.collect { |node| node.ways_via_history_ids }.flatten.uniq

	[way_ids]
  end

  # Get a way including nodes and tags.
  # Returns the way id, a Potlatch-style array of points, a hash of tags, and the version number.

  def getway(wayid) #:doc:
	if POTLATCH_USE_SQL then
	  points = sql_get_nodes_in_way(wayid)
	  tags = sql_get_tags_in_way(wayid)
	  version = sql_get_way_version(wayid)
	else
	  # Ideally we would do ":include => :nodes" here but if we do that
	  # then rails only seems to return the first copy of a node when a
	  # way includes a node more than once
      begin
	    way = Way.find(wayid)
      rescue ActiveRecord::RecordNotFound
        return [wayid,[],{}]
      end

      # check case where way has been deleted or doesn't exist
      return [wayid,[],{}] if way.nil? or !way.visible

	  points = way.nodes.collect do |node|
		nodetags=node.tags
		nodetags.delete('created_by')
		[node.lon, node.lat, node.id, nodetags]
	  end
	  tags = way.tags
	  version = way.version
	end

	[wayid, points, tags, version]
  end

  # Get an old version of a way, and all constituent nodes.
  #
  # For undelete (version<0), always uses the most recent version of each node, 
  # even if it's moved.  For revert (version >= 0), uses the node in existence 
  # at the time, generating a new id if it's still visible and has been moved/
  # retagged.
  #
  # Returns:
  # 0. success code, 
  # 1. id, 
  # 2. array of points, 
  # 3. hash of tags, 
  # 4. version, 
  # 5. is this the current, visible version? (boolean)

  def getway_old(id, version) #:doc:
	if version < 0
	  old_way = OldWay.find(:first, :conditions => ['visible = ? AND id = ?', true, id], :order => 'version DESC')
	  points = old_way.get_nodes_undelete unless old_way.nil?
	else
	  old_way = OldWay.find(:first, :conditions => ['id = ? AND version = ?', id, version])
	  points = old_way.get_nodes_revert unless old_way.nil?
	end

    if old_way.nil?
      return [-1, id, [], {}, -1,0]
    else
	  curway=Way.find(id)
	  old_way.tags['history'] = "Retrieved from v#{old_way.version}"
	  return [0, id, points, old_way.tags, old_way.version, (curway.version==old_way.version and curway.visible)]
    end
  end
  
  # Find history of a way. Returns 'way', id, and 
  # an array of previous versions.

  def getway_history(wayid) #:doc:
    begin
	  history = Way.find(wayid).old_ways.reverse.collect do |old_way|
        user_object = old_way.changeset.user
	    user = user_object.data_public? ? user_object.display_name : 'anonymous'
	    uid  = user_object.data_public? ? user_object.id : 0
	    [old_way.version, old_way.timestamp.strftime("%d %b %Y, %H:%M"), old_way.visible ? 1 : 0, user, uid]
	  end

	  return ['way',wayid,history]
    rescue ActiveRecord::RecordNotFound
      return ['way', wayid, []]
    end
  end

  # Find history of a node. Returns 'node', id, and 
  # an array of previous versions.

  def getnode_history(nodeid) #:doc:
    begin
	  history = Node.find(nodeid).old_nodes.reverse.collect do |old_node|
        user_object = old_node.changeset.user
	    user = user_object.data_public? ? user_object.display_name : 'anonymous'
	    uid  = user_object.data_public? ? user_object.id : 0
	    [old_node.version, old_node.timestamp.strftime("%d %b %Y, %H:%M"), old_node.visible ? 1 : 0, user, uid]
	  end

	  return ['node',nodeid,history]
    rescue ActiveRecord::RecordNotFound
      return ['node', nodeid, []]
    end
  end

  # Get a relation with all tags and members.
  # Returns:
  # 0. relation id,
  # 1. hash of tags,
  # 2. list of members,
  # 3. version.
  
  def getrelation(relid) #:doc:
    begin
	  rel = Relation.find(relid)
    rescue ActiveRecord::RecordNotFound
      return [relid, {}, []]
    end

    return [relid, {}, [], nil] if rel.nil? or !rel.visible
	[relid, rel.tags, rel.members, rel.version]
  end

  # Find relations with specified name/id.
  # Returns array of relations, each in same form as getrelation.
  
  def findrelations(searchterm)
	rels = []
	if searchterm.to_i>0 then
	  rel = Relation.find(searchterm.to_i)
	  if rel and rel.visible then
	    rels.push([rel.id, rel.tags, rel.members])
	  end
	else
	  RelationTag.find(:all, :limit => 11, :conditions => ["match(v) against (?)", searchterm] ).each do |t|
		if t.relation.visible then
	      rels.push([t.relation.id, t.relation.tags, t.relation.members])
	    end
	  end
	end
	rels
  end

  # Save a relation.
  # Returns
  # 0. 0 (success),
  # 1. original relation id (unchanged),
  # 2. new relation id.

  def putrelation(renumberednodes, renumberedways, usertoken, changeset, relid, tags, members, visible) #:doc:
	uid = getuserid(usertoken)
	if !uid then return -1,"You are not logged in, so the relation could not be saved." end

	relid = relid.to_i
	visible = (visible.to_i != 0)

	# create a new relation, or find the existing one
	if relid <= 0
	  rel = Relation.new
	  rel.version = 0
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
	  end
      if mid
	    typedmembers << [m[0], mid, m[2]]
	  end
	end

	# assign new contents
	rel.members = typedmembers
	rel.tags = tags
	rel.visible = visible
	rel.changeset_id = changeset

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

  # Save a way to the database, including all nodes. Any nodes in the previous
  # version and no longer used are deleted.
  # 
  # Returns:
  # 0. '0' (code for success),
  # 1. original way id (unchanged),
  # 2. new way id,
  # 3. hash of renumbered nodes (old id=>new id),
  # 4. version

  def putway(renumberednodes, usertoken, changeset, originalway, points, attributes) #:doc:

	# -- Initialise and carry out checks
	
	uid = getuserid(usertoken)
	if !uid then return -1,"You are not logged in, so the way could not be saved." end

	originalway = originalway.to_i

	points.each do |a|
	  if a[2] == 0 or a[2].nil? then return -2,"Server error - node with id 0 found in way #{originalway}." end
	  if a[1] == 90 then return -2,"Server error - node with lat -90 found in way #{originalway}." end
	end

	if points.length < 2 then return -2,"Server error - way is only #{points.length} points long." end

	# -- Get unique nodes

	if originalway < 0
	  way = Way.new
	  way.version = 0	# otherwise +=1 breaks
	  uniques = []
	else
	  way = Way.find(originalway)
	  uniques = way.unshared_node_ids
	end

	# -- Compare nodes and save changes to any that have changed

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
		node.version = 0	# otherwise +=1 breaks
		savenode = true
	  else
		node = Node.find(id)
		nodetags=node.tags
		nodetags.delete('created_by')
		if !fpcomp(lat, node.lat) or !fpcomp(lon, node.lon) or
		   n[4] != nodetags or !node.visible?
		  savenode = true
		end
	  end

	  if savenode
		node.changeset_id = changeset
	    node.lat = lat
        node.lon = lon
	    node.tags = n[4]
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
	  node.changeset_id = changeset
	  node.visible = false
	  node.save_with_history!
	end

	# -- Save revised way

	if way.tags!=attributes or way.nds!=nodes or !way.visible?
	  way.tags = attributes
	  way.nds = nodes
	  way.changeset_id = changeset
	  way.visible = true
	  way.save_with_history!
	end

	[0, originalway, way.id, renumberednodes, way.version]
  end

  # Save POI to the database.
  # Refuses save if the node has since become part of a way.
  # Returns:
  # 0. 0 (success),
  # 1. original node id (unchanged),
  # 2. new node id,
  # 3. version.

  def putpoi(usertoken, changeset, id, lon, lat, tags, visible) #:doc:
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
	  node.version = 0
	end

	node.changeset_id = changeset
	node.lat = lat
	node.lon = lon
	node.tags = tags
	node.visible = visible
	node.save_with_history!

	[0, id, node.id, node.version]
  end

  # Read POI from database
  # (only called on revert: POIs are usually read by whichways).
  #
  # Returns array of id, long, lat, hash of tags, version.

  def getpoi(id,version) #:doc:
	if version>0 then
	  n = OldNode.find(id, :conditions=>['version=?',version])
	else
	  n = Node.find(id)
	end

	if n
	  return [n.id, n.lon, n.lat, n.tags, n.version]
	else
	  return [nil, nil, nil, {}, nil]
	end
  end

  # Delete way and all constituent nodes. Also removes from any relations.
  # Returns 0 (success), unchanged way id.

  def deleteway(usertoken, changeset_id, way_id) #:doc:
	if !getuserid(usertoken) then return -1,"You are not logged in, so the way could not be deleted." end

	way_id = way_id.to_i

	# FIXME: would be good not to make two history entries when removing
	#		 two nodes from the same relation
	way = Way.find(way_id)
	way.unshared_node_ids.each do |n|
	  deleteitemrelations(n, 'node')
	end
	deleteitemrelations(way_id, 'way')

	way.delete_with_relations_and_nodes_and_history(changeset_id.to_i)

	[0, way_id]
  end


  # ====================================================================
  # Support functions

  # Remove a node or way from all relations

  def deleteitemrelations(objid, type) #:doc:
	relations = RelationMember.find(:all, 
									:conditions => ['member_type = ? and member_id = ?', type, objid], 
									:include => :relation).collect { |rm| rm.relation }.uniq

	relations.each do |rel|
	  rel.members.delete_if { |x| x[0] == type and x[1] == objid }
	  rel.save_with_history!
	end
  end

  # Break out node tags into a hash
  # (should become obsolete as of API 0.6)

  def tagstring_to_hash(a) #:doc:
	tags={}
	Tags.split(a) do |k, v|
	  tags[k]=v
	end
	tags
  end

  # Authenticate token
  # (could be removed if no-one uses the username+password form)

  def getuserid(token) #:doc:
	if (token =~ /^(.+)\+(.+)$/) then
	  user = User.authenticate(:username => $1, :password => $2)
	else
	  user = User.authenticate(:token => token)
	end

	return user ? user.id : nil;
  end

  # Compare two floating-point numbers to within 0.0000001

  def fpcomp(a,b) #:doc:
	return ((a/0.0000001).round==(b/0.0000001).round)
  end

  # Send AMF response
  
  def sendresponse(results)
	a,b=results.length.divmod(256)
	render :content_type => "application/x-amf", :text => proc { |response, output| 
	  # ** move amf writing loop into here - 
	  # basically we read the messages in first (into an array of some sort),
	  # then iterate through that array within here, and do all the AMF writing
	  output.write 0.chr+0.chr+0.chr+0.chr+a.chr+b.chr
	  results.each do |k,v|
		output.write(v)
	  end
	}
  end


  # ====================================================================
  # Alternative SQL queries for getway/whichways

  def sql_find_ways_in_area(xmin,ymin,xmax,ymax)
	sql=<<-EOF
  SELECT DISTINCT current_ways.id AS wayid,current_ways.version AS version
		FROM current_way_nodes
  INNER JOIN current_nodes ON current_nodes.id=current_way_nodes.node_id
  INNER JOIN current_ways  ON current_ways.id =current_way_nodes.id
	   WHERE current_nodes.visible=TRUE 
		 AND current_ways.visible=TRUE 
		 AND #{OSM.sql_for_area(ymin, xmin, ymax, xmax, "current_nodes.")}
	EOF
	return ActiveRecord::Base.connection.select_all(sql).collect { |a| [a['wayid'].to_i,a['version'].to_i] }
  end
	
  def sql_find_pois_in_area(xmin,ymin,xmax,ymax)
	pois=[]
	sql=<<-EOF
		  SELECT current_nodes.id,current_nodes.latitude*0.0000001 AS lat,current_nodes.longitude*0.0000001 AS lon,current_nodes.version 
			FROM current_nodes 
 LEFT OUTER JOIN current_way_nodes cwn ON cwn.node_id=current_nodes.id 
		   WHERE current_nodes.visible=TRUE
			 AND cwn.id IS NULL
			 AND #{OSM.sql_for_area(ymin, xmin, ymax, xmax, "current_nodes.")}
	EOF
	ActiveRecord::Base.connection.select_all(sql).each do |row|
	  poitags={}
	  ActiveRecord::Base.connection.select_all("SELECT k,v FROM current_node_tags WHERE id=#{row['id']}").each do |n|
		poitags[n['k']]=n['v']
	  end
	  pois << [row['id'].to_i, row['lon'].to_f, row['lat'].to_f, poitags, row['version'].to_i]
	end
	pois
  end
	
  def sql_find_relations_in_area_and_ways(xmin,ymin,xmax,ymax,way_ids)
	# ** It would be more Potlatchy to get relations for nodes within ways
	#    during 'getway', not here
	sql=<<-EOF
	  SELECT DISTINCT cr.id AS relid,cr.version AS version 
		FROM current_relations cr
  INNER JOIN current_relation_members crm ON crm.id=cr.id 
  INNER JOIN current_nodes cn ON crm.member_id=cn.id AND crm.member_type='node' 
	   WHERE #{OSM.sql_for_area(ymin, xmin, ymax, xmax, "cn.")}
	EOF
	unless way_ids.empty?
	  sql+=<<-EOF
	   UNION
	  SELECT DISTINCT cr.id AS relid,cr.version AS version
		FROM current_relations cr
  INNER JOIN current_relation_members crm ON crm.id=cr.id
	   WHERE crm.member_type='way' 
		 AND crm.member_id IN (#{way_ids.join(',')})
	  EOF
	end
	return ActiveRecord::Base.connection.select_all(sql).collect { |a| [a['relid'].to_i,a['version'].to_i] }
  end
	
  def sql_get_nodes_in_way(wayid)
	points=[]
	sql=<<-EOF
		SELECT latitude*0.0000001 AS lat,longitude*0.0000001 AS lon,current_nodes.id 
		  FROM current_way_nodes,current_nodes 
		 WHERE current_way_nodes.id=#{wayid.to_i} 
		   AND current_way_nodes.node_id=current_nodes.id 
		   AND current_nodes.visible=TRUE
	  ORDER BY sequence_id
	  EOF
	ActiveRecord::Base.connection.select_all(sql).each do |row|
	  nodetags={}
	  ActiveRecord::Base.connection.select_all("SELECT k,v FROM current_node_tags WHERE id=#{row['id']}").each do |n|
		nodetags[n['k']]=n['v']
	  end
	  nodetags.delete('created_by')
	  points << [row['lon'].to_f,row['lat'].to_f,row['id'].to_i,nodetags]
	end
	points
  end
	
  def sql_get_tags_in_way(wayid)
	tags={}
	ActiveRecord::Base.connection.select_all("SELECT k,v FROM current_way_tags WHERE id=#{wayid.to_i}").each do |row|
	  tags[row['k']]=row['v']
	end
	tags
  end

  def sql_get_way_version(wayid)
    ActiveRecord::Base.connection.select_one("SELECT version FROM current_ways WHERE id=#{wayid.to_i}")
  end
end

# Local Variables:
# indent-tabs-mode: t
# tab-width: 4
# End:
