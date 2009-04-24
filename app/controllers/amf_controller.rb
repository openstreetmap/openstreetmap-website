# amf_controller is a semi-standalone API for Flash clients, particularly 
# Potlatch. All interaction between Potlatch (as a .SWF application) and the 
# OSM database takes place using this controller. Messages are 
# encoded in the Actionscript Message Format (AMF).
#
# Helper functions are in /lib/potlatch.rb
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
# == API 0.6
#
# Note that this requires a patched version of composite_primary_keys 1.1.0
# (see http://groups.google.com/group/compositekeys/t/a00e7562b677e193) 
# if you are to run with POTLATCH_USE_SQL=false .
# 
# == Debugging
# 
# Any method that returns a status code (0 for ok) can also send:
#	return(-1,"message")		<-- just puts up a dialogue
#	return(-2,"message")		<-- also asks the user to e-mail me
# 
# To write to the Rails log, use logger.info("message").

# Remaining issues:
# * version conflict when POIs and ways are reverted

class AmfController < ApplicationController
  require 'stringio'

  include Potlatch

  # Help methods for checking boundary sanity and area size
  include MapBoundary

  session :off
  before_filter :check_api_writable

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
      logger.info("Executing AMF #{message}:#{index}")

      case message
        when 'getpresets';			results[index]=AMF.putdata(index,getpresets())
        when 'whichways';			results[index]=AMF.putdata(index,whichways(*args))
        when 'whichways_deleted';	results[index]=AMF.putdata(index,whichways_deleted(*args))
        when 'getway';				r=AMF.putdata(index,getway(args[0].to_i))
                                    results[index]=r
        when 'getrelation';			results[index]=AMF.putdata(index,getrelation(args[0].to_i))
        when 'getway_old';			results[index]=AMF.putdata(index,getway_old(args[0].to_i,args[1]))
        when 'getway_history';		results[index]=AMF.putdata(index,getway_history(args[0].to_i))
        when 'getnode_history';		results[index]=AMF.putdata(index,getnode_history(args[0].to_i))
        when 'findgpx';				results[index]=AMF.putdata(index,findgpx(*args))
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

      logger.info("Executing AMF #{message}:#{index}")
      case message
        when 'putway';				r=putway(renumberednodes,*args)
									renumberednodes=r[3]
									if r[1] != r[2] then renumberedways[r[1]] = r[2] end
									results[index]=AMF.putdata(index,r)
        when 'putrelation';			results[index]=AMF.putdata(index,putrelation(renumberednodes, renumberedways, *args))
        when 'deleteway';			results[index]=AMF.putdata(index,deleteway(*args))
        when 'putpoi';				r=putpoi(*args)
									if r[1] != r[2] then renumberednodes[r[1]] = r[2] end
        							results[index]=AMF.putdata(index,r)
        when 'startchangeset';		results[index]=AMF.putdata(index,startchangeset(*args))
      end
    end
    logger.info("encoding AMF results")
    sendresponse(results)
  end

  private

  # Start new changeset
  
  def startchangeset(usertoken, cstags, closeid, closecomment)
    user = getuser(usertoken)
    if !user then return -1,"You are not logged in, so Potlatch can't write any changes to the database." end

    # close previous changeset and add comment
    if closeid
      cs = Changeset.find(closeid)
      cs.set_closed_time_now
      if cs.user_id!=user.id
        return -2,"You cannot close that changeset because you're not the person who opened it."
      elsif closecomment.empty?
        cs.save!
      else
        cs.tags['comment']=closecomment
        cs.save_with_tags!
      end
    end
	
    # open a new changeset
    cs = Changeset.new
    cs.tags = cstags
    cs.user_id = user.id
    # smsm1 doesn't like the next two lines and thinks they need to be abstracted to the model more/better
    cs.created_at = Time.now.getutc
    cs.closed_at = cs.created_at + Changeset::IDLE_TIMEOUT
    cs.save_with_tags!
    return [0,cs.id]
  end

  # Return presets (default tags, localisation etc.):
  # uses POTLATCH_PRESETS global, set up in OSM::Potlatch.

  def getpresets() #:doc:
    return POTLATCH_PRESETS
  end

  ##
  # Find all the ways, POI nodes (i.e. not part of ways), and relations
  # in a given bounding box. Nodes are returned in full; ways and relations 
  # are IDs only. 
  #
  # return is of the form: 
  # [error_code, 
  #  [[way_id, way_version], ...],
  #  [[node_id, lat, lon, [tags, ...], node_version], ...],
  #  [[rel_id, rel_version], ...]]
  # where the ways are any visible ways which refer to any visible
  # nodes in the bbox, nodes are any visible nodes in the bbox but not
  # used in any way, rel is any relation which refers to either a way
  # or node that we're returning.
  def whichways(xmin, ymin, xmax, ymax) #:doc:
    enlarge = [(xmax-xmin)/8,0.01].min
    xmin -= enlarge; ymin -= enlarge
    xmax += enlarge; ymax += enlarge
    
    # check boundary is sane and area within defined
    # see /config/application.yml
    check_boundaries(xmin, ymin, xmax, ymax)

    if POTLATCH_USE_SQL then
      ways = sql_find_ways_in_area(xmin, ymin, xmax, ymax)
      points = sql_find_pois_in_area(xmin, ymin, xmax, ymax)
      relations = sql_find_relations_in_area_and_ways(xmin, ymin, xmax, ymax, ways.collect {|x| x[0]})
    else
      # find the way ids in an area
      nodes_in_area = Node.find_by_area(ymin, xmin, ymax, xmax, :conditions => ["current_nodes.visible = ?", true], :include => :ways)
      ways = nodes_in_area.inject([]) { |sum, node| 
        visible_ways = node.ways.select { |w| w.visible? }
        sum + visible_ways.collect { |w| [w.id,w.version] }
      }.uniq
      ways.delete([])

      # find the node ids in an area that aren't part of ways
      nodes_not_used_in_area = nodes_in_area.select { |node| node.ways.empty? }
      points = nodes_not_used_in_area.collect { |n| [n.id, n.lon, n.lat, n.tags, n.version] }.uniq

      # find the relations used by those nodes and ways
      relations = Relation.find_for_nodes(nodes_in_area.collect { |n| n.id }, :conditions => {:visible => true}) +
                  Relation.find_for_ways(ways.collect { |w| w[0] }, :conditions => {:visible => true})
      relations = relations.collect { |relation| [relation.id,relation.version] }.uniq
    end

    [0, ways, points, relations]

  rescue Exception => err
    [-2,"Sorry - I can't get the map for that area. The server said: #{err}"]
  end

  # Find deleted ways in current bounding box (similar to whichways, but ways
  # with a deleted node only - not POIs or relations).

  def whichways_deleted(xmin, ymin, xmax, ymax) #:doc:
    enlarge = [(xmax-xmin)/8,0.01].min
    xmin -= enlarge; ymin -= enlarge
    xmax += enlarge; ymax += enlarge

    # check boundary is sane and area within defined
    # see /config/application.yml
    begin
      check_boundaries(xmin, ymin, xmax, ymax)
    rescue Exception => err
      return [-2,"Sorry - I can't get the map for that area. The server said: #{err}"]
    end

    nodes_in_area = Node.find_by_area(ymin, xmin, ymax, xmax, :conditions => ["current_ways.visible = ?", false], :include => :ways_via_history)
    way_ids = nodes_in_area.collect { |node| node.ways_via_history_ids }.flatten.uniq

    [0,way_ids]
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
        [node.lon, node.lat, node.id, nodetags, node.version]
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
  
  def getway_old(id, timestamp) #:doc:
    if timestamp == ''
      # undelete
      old_way = OldWay.find(:first, :conditions => ['visible = ? AND id = ?', true, id], :order => 'version DESC')
      points = old_way.get_nodes_undelete unless old_way.nil?
    else
      begin
        # revert
        timestamp = DateTime.strptime(timestamp.to_s, "%d %b %Y, %H:%M:%S")
        old_way = OldWay.find(:first, :conditions => ['id = ? AND timestamp <= ?', id, timestamp], :order => 'timestamp DESC')
        unless old_way.nil?
          points = old_way.get_nodes_revert(timestamp)
          if !old_way.visible
            return [-1, "Sorry, the way was deleted at that time - please revert to a previous version."]
          end
        end
      rescue ArgumentError
        # thrown by date parsing method. leave old_way as nil for
        # the superb error handler below.
      end
    end

    if old_way.nil?
      # *** FIXME: shouldn't this be returning an error?
      return [-1, id, [], {}, -1,0]
    else
      curway=Way.find(id)
      old_way.tags['history'] = "Retrieved from v#{old_way.version}"
      return [0, id, points, old_way.tags, curway.version, (curway.version==old_way.version and curway.visible)]
    end
  end
  
  # Find history of a way.
  # Returns 'way', id, and an array of previous versions:
  # - formerly [old_way.version, old_way.timestamp.strftime("%d %b %Y, %H:%M"), old_way.visible ? 1 : 0, user, uid]
  # - now [timestamp,user,uid]
  #
  # Heuristic: Find all nodes that have ever been part of the way; 
  # get a list of their revision dates; add revision dates of the way;
  # sort and collapse list (to within 2 seconds); trim all dates before the 
  # start date of the way.

  def getway_history(wayid) #:doc:

    begin
      # Find list of revision dates for way and all constituent nodes
      revdates=[]
      revusers={}
      Way.find(wayid).old_ways.collect do |a|
        revdates.push(a.timestamp)
        unless revusers.has_key?(a.timestamp.to_i) then revusers[a.timestamp.to_i]=change_user(a) end
        a.nds.each do |n|
          Node.find(n).old_nodes.collect do |o|
            revdates.push(o.timestamp)
            unless revusers.has_key?(o.timestamp.to_i) then revusers[o.timestamp.to_i]=change_user(o) end
          end
        end
      end
      waycreated=revdates[0]
      revdates.uniq!
      revdates.sort!
	  revdates.reverse!

      # Remove any dates (from nodes) before first revision date of way
      revdates.delete_if { |d| d<waycreated }
      # Remove any elements where 2 seconds doesn't elapse before next one
      revdates.delete_if { |d| revdates.include?(d+1) or revdates.include?(d+2) }
      # Collect all in one nested array
      revdates.collect! {|d| [d.strftime("%d %b %Y, %H:%M:%S")] + revusers[d.to_i] }

      return ['way',wayid,revdates]
    rescue ActiveRecord::RecordNotFound
      return ['way', wayid, []]
    end
  end
  
  # Find history of a node. Returns 'node', id, and an array of previous versions as above.

  def getnode_history(nodeid) #:doc:
    begin 
      history = Node.find(nodeid).old_nodes.reverse.collect do |old_node|
        [old_node.timestamp.strftime("%d %b %Y, %H:%M:%S")] + change_user(old_node)
      end
      return ['node', nodeid, history]
    rescue ActiveRecord::RecordNotFound
      return ['node', nodeid, []]
    end
  end

  def change_user(obj)
    user_object = obj.changeset.user
    user = user_object.data_public? ? user_object.display_name : 'anonymous'
    uid  = user_object.data_public? ? user_object.id : 0
    [user,uid]
  end

  # Find GPS traces with specified name/id.
  # Returns array listing GPXs, each one comprising id, name and description.
  
  def findgpx(searchterm, usertoken)
    user = getuser(usertoken)
    if !uid then return -1,"You must be logged in to search for GPX traces." end

    gpxs = []
    if searchterm.to_i>0 then
      gpx = Trace.find(searchterm.to_i, :conditions => ["visible=? AND (public=? OR user_id=?)",true,true,user.id] )
      if gpx then
        gpxs.push([gpx.id, gpx.name, gpx.description])
      end
    else
      Trace.find(:all, :limit => 21, :conditions => ["visible=? AND (public=? OR user_id=?) AND MATCH(name) AGAINST (?)",true,true,user.id,searchterm] ).each do |gpx|
      gpxs.push([gpx.id, gpx.name, gpx.description])
	  end
	end
    gpxs
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
        rels.push([rel.id, rel.tags, rel.members, rel.version])
      end
    else
      RelationTag.find(:all, :limit => 11, :conditions => ["match(v) against (?)", searchterm] ).each do |t|
      if t.relation.visible then
	      rels.push([t.relation.id, t.relation.tags, t.relation.members, t.relation.version])
	    end
	  end
	end
    rels
  end

  # Save a relation.
  # Returns
  # 0. 0 (success),
  # 1. original relation id (unchanged),
  # 2. new relation id,
  # 3. version.

  def putrelation(renumberednodes, renumberedways, usertoken, changeset_id, version, relid, tags, members, visible) #:doc:
    user = getuser(usertoken)
    if !user then return -1,"You are not logged in, so the relation could not be saved." end

    relid = relid.to_i
    visible = (visible.to_i != 0)

    new_relation = nil
    relation = nil
    Relation.transaction do
      # create a new relation, or find the existing one
      if relid > 0
        relation = Relation.find(relid)
      end
      # We always need a new node, based on the data that has been sent to us
      new_relation = Relation.new

      # check the members are all positive, and correctly type
      typedmembers = []
      members.each do |m|
        mid = m[1].to_i
        if mid < 0
          mid = renumberednodes[mid] if m[0] == 'Node'
          mid = renumberedways[mid] if m[0] == 'Way'
        end
        if mid
          typedmembers << [m[0], mid, m[2]]
        end
      end

      # assign new contents
      new_relation.members = typedmembers
      new_relation.tags = tags
      new_relation.visible = visible
      new_relation.changeset_id = changeset_id
      new_relation.version = version

      if relid <= 0
        # We're creating the node
        new_relation.create_with_history(user)
      elsif visible
        # We're updating the node
        relation.update_from(new_relation, user)
      else
        # We're deleting the node
        relation.delete_with_history!(new_relation, user)
      end
    end # transaction
      
    if relid <= 0
      return [0, relid, new_relation.id, new_relation.version]
    else
      return [0, relid, relid, relation.version]
    end
  rescue OSM::APIChangesetAlreadyClosedError => ex
    return [-1, "The changeset #{ex.changeset.id} was closed at #{ex.changeset.closed_at}."]
  rescue OSM::APIVersionMismatchError => ex
    # Really need to check to see whether this is a server load issue, and the 
    # last version was in the same changeset, or belongs to the same user, then
    # we can return something different
    return [-3, "Sorry, someone else has changed this relation since you started editing. Please click the 'Edit' tab to reload the area. The server said: #{ex}"]
  rescue OSM::APIAlreadyDeletedError => ex
    return [-1, "The relation has already been deleted."]
  rescue OSM::APIError => ex
    # Some error that we don't specifically catch
    return [-2, "An unusual error happened (in 'putrelation' #{relid}). The server said: #{ex}"]
  end

  # Save a way to the database, including all nodes. Any nodes in the previous
  # version and no longer used are deleted.
  # 
  # Parameters:
  # 0. hash of renumbered nodes (added by amf_controller)
  # 1. current user token (for authentication)
  # 2. current changeset
  # 3. new way version
  # 4. way ID
  # 5. list of nodes in way
  # 6. hash of way tags
  # 7. array of nodes to change (each one is [lon,lat,id,version,tags])
  # 
  # Returns:
  # 0. '0' (code for success),
  # 1. original way id (unchanged),
  # 2. new way id,
  # 3. hash of renumbered nodes (old id=>new id),
  # 4. way version,
  # 5. hash of node versions (node=>version)

  def putway(renumberednodes, usertoken, changeset_id, wayversion, originalway, pointlist, attributes, nodes) #:doc:

    # -- Initialise
	
    user = getuser(usertoken)
    if !user then return -1,"You are not logged in, so the way could not be saved." end
    if pointlist.length < 2 then return -2,"Server error - way is only #{points.length} points long." end

    originalway = originalway.to_i
	pointlist.collect! {|a| a.to_i }

    way=nil	# this is returned, so scope it outside the transaction
    nodeversions = {}
    Way.transaction do

      # -- Get unique nodes

      if originalway <= 0
        uniques = []
      else
        way = Way.find(originalway)
        uniques = way.unshared_node_ids
      end

      #-- Update each changed node

      nodes.each do |a|
        lon = a[0].to_f
        lat = a[1].to_f
        id = a[2].to_i
        version = a[3].to_i
        if id == 0  then return -2,"Server error - node with id 0 found in way #{originalway}." end
        if lat== 90 then return -2,"Server error - node with latitude -90 found in way #{originalway}." end
        if renumberednodes[id] then id = renumberednodes[id] end

        node = Node.new
        node.changeset_id = changeset_id
        node.lat = lat
        node.lon = lon
        node.tags = a[4]
        node.tags.delete('created_by')
        node.version = version
        if id <= 0
          # We're creating the node
          node.create_with_history(user)
          renumberednodes[id] = node.id
          nodeversions[node.id] = node.version
        else
          # We're updating an existing node
          previous=Node.find(id)
          previous.update_from(node, user)
          nodeversions[previous.id] = previous.version
        end
      end

      # -- Save revised way

	  pointlist.collect! {|a|
		renumberednodes[a] ? renumberednodes[a]:a
	  } # renumber nodes
      new_way = Way.new
      new_way.tags = attributes
      new_way.nds = pointlist
      new_way.changeset_id = changeset_id
      new_way.version = wayversion
      if originalway <= 0
        new_way.create_with_history(user)
        way=new_way	# so we can get way.id and way.version
      elsif way.tags!=attributes or way.nds!=pointlist or !way.visible?
        way.update_from(new_way, user)
      end

      # -- Delete any unique nodes no longer used

      uniques=uniques-pointlist
      uniques.each do |n|
        node = Node.find(n)
        deleteitemrelations(user, changeset_id, id, 'Node', node.version)
        new_node = Node.new
        new_node.changeset_id = changeset_id
        new_node.version = node.version
        node.delete_with_history!(new_node, user)
      end

    end # transaction

    [0, originalway, way.id, renumberednodes, way.version, nodeversions]
  rescue OSM::APIChangesetAlreadyClosedError => ex
    return [-2, "Sorry, your changeset #{ex.changeset.id} has been closed (at #{ex.changeset.closed_at})."]
  rescue OSM::APIVersionMismatchError => ex
    # Really need to check to see whether this is a server load issue, and the 
    # last version was in the same changeset, or belongs to the same user, then
    # we can return something different
    return [-3, "Sorry, someone else has changed this way since you started editing. Click the 'Edit' tab to reload the area. The server said: #{ex}"]
  rescue OSM::APITooManyWayNodesError => ex
    return [-1, "You have tried to upload a really long way with #{ex.provided} points: only #{ex.max} are allowed."]
  rescue OSM::APIAlreadyDeletedError => ex
    return [-1, "The point has already been deleted."]
  rescue OSM::APIError => ex
    # Some error that we don't specifically catch
    return [-2, "An unusual error happened (in 'putway' #{originalway}). The server said: #{ex}"]
  end

  # Save POI to the database.
  # Refuses save if the node has since become part of a way.
  # Returns array with:
  # 0. 0 (success),
  # 1. original node id (unchanged),
  # 2. new node id,
  # 3. version.

  def putpoi(usertoken, changeset_id, version, id, lon, lat, tags, visible) #:doc:
    user = getuser(usertoken)
    if !user then return -1,"You are not logged in, so the point could not be saved." end

    id = id.to_i
    visible = (visible.to_i == 1)
    node = nil
    new_node = nil
    Node.transaction do
      if id > 0 then
        node = Node.find(id)

        if !visible then
          unless node.ways.empty? then return -1,"The point has since become part of a way, so you cannot save it as a POI." end
        end
      end
      # We always need a new node, based on the data that has been sent to us
      new_node = Node.new

      new_node.changeset_id = changeset_id
      new_node.version = version
      new_node.lat = lat
      new_node.lon = lon
      new_node.tags = tags
      if id <= 0 
        # We're creating the node
        new_node.create_with_history(user)
      elsif visible
        # We're updating the node
        node.update_from(new_node, user)
      else
        # We're deleting the node
        node.delete_with_history!(new_node, user)
      end
     end # transaction

    if id <= 0
      return [0, id, new_node.id, new_node.version]
    else
      return [0, id, node.id, node.version]
    end 
  rescue OSM::APIChangesetAlreadyClosedError => ex
    return [-1, "The changeset #{ex.changeset.id} was closed at #{ex.changeset.closed_at}"]
  rescue OSM::APIVersionMismatchError => ex
    # Really need to check to see whether this is a server load issue, and the 
    # last version was in the same changeset, or belongs to the same user, then
    # we can return something different
    return [-3, "Sorry, someone else has changed this point since you started editing. Please click the 'Edit' tab to reload the area. The server said: #{ex}"]
  rescue OSM::APIAlreadyDeletedError => ex
    return [-1, "The point has already been deleted"]
  rescue OSM::APIError => ex
    # Some error that we don't specifically catch
    return [-2, "An unusual error happened (in 'putpoi' #{id}). The server said: #{ex}"]
  end

  # Read POI from database
  # (only called on revert: POIs are usually read by whichways).
  #
  # Returns array of id, long, lat, hash of tags, (current) version.

  def getpoi(id,timestamp) #:doc:
    n = Node.find(id)
    v = n.version
    unless timestamp == ''
      n = OldNode.find(id, :conditions=>['timestamp=?',DateTime.strptime(timestamp, "%d %b %Y, %H:%M:%S")])
    end

    if n
      return [n.id, n.lon, n.lat, n.tags, v]
    else
      return [nil, nil, nil, {}, nil]
    end
  end

  # Delete way and all constituent nodes. Also removes from any relations.
  # Params:
  # * The user token
  # * the changeset id
  # * the id of the way to change
  # * the version of the way that was downloaded
  # * a hash of the id and versions of all the nodes that are in the way, if any 
  # of the nodes have been changed by someone else then, there is a problem!
  # Returns 0 (success), unchanged way id.

  def deleteway(usertoken, changeset_id, way_id, way_version, node_id_version) #:doc:
    user = getuser(usertoken)
    unless user then return -1,"You are not logged in, so the way could not be deleted." end
      
    way_id = way_id.to_i
    # Need a transaction so that if one item fails to delete, the whole delete fails.
    Way.transaction do

      # delete the way
      old_way = Way.find(way_id)
      u = old_way.unshared_node_ids
      delete_way = Way.new
      delete_way.version = way_version
      delete_way.changeset_id = changeset_id
      old_way.delete_with_history!(delete_way, user)

      u.each do |node_id|
        # delete the node
        node = Node.find(node_id)
        delete_node = Node.new
        delete_node.changeset_id = changeset_id
        if node_id_version[node_id.to_s]
          delete_node.version = node_id_version[node_id.to_s]
        else
          # in case the node wasn't passed (i.e. if it was previously removed
          # from the way in Potlatch)
          deleteitemrelations(user, changeset_id, node_id, 'Node', node.version)
	      delete_node.version = node.version
	    end
        node.delete_with_history!(delete_node, user)
      end
    end # transaction
    [0, way_id]
  rescue OSM::APIChangesetAlreadyClosedError => ex
    return [-1, "The changeset #{ex.changeset.id} was closed at #{ex.changeset.closed_at}"]
  rescue OSM::APIVersionMismatchError => ex
    # Really need to check to see whether this is a server load issue, and the 
    # last version was in the same changeset, or belongs to the same user, then
    # we can return something different
    return [-3, "Sorry, someone else has changed this way since you started editing. Please click the 'Edit' tab to reload the area."]
  rescue OSM::APIAlreadyDeletedError => ex
    return [-1, "The way has already been deleted."]
  rescue OSM::APIError => ex
    # Some error that we don't specifically catch
    return [-2, "An unusual error happened (in 'deleteway' #{way_id}). The server said: #{ex}"]
  end


  # ====================================================================
  # Support functions

  # Remove a node or way from all relations
  # This is only used by putway and deleteway when deleting nodes removed 
  # from a way (because Potlatch itself doesn't keep track of these - 
  # possible FIXME).

  def deleteitemrelations(user, changeset_id, objid, type, version) #:doc:
    relations = RelationMember.find(:all, 
									:conditions => ['member_type = ? and member_id = ?', type.classify, objid], 
									:include => :relation).collect { |rm| rm.relation }.uniq

    relations.each do |rel|
      rel.members.delete_if { |x| x[0] == type and x[1] == objid }
      new_rel = Relation.new
      new_rel.tags = rel.tags
      new_rel.visible = rel.visible
      new_rel.version = rel.version
      new_rel.members = rel.members
      new_rel.changeset_id = changeset_id
      rel.update_from(new_rel, user)
    end
  end

  # Authenticate token
  # (can also be of form user:pass)
  # When we are writing to the api, we need the actual user model, 
  # not just the id, hence this abstraction

  def getuser(token) #:doc:
    if (token =~ /^(.+)\:(.+)$/) then
      user = User.authenticate(:username => $1, :password => $2)
    else
      user = User.authenticate(:token => token)
    end
    return user
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
      INNER JOIN current_nodes cn ON crm.member_id=cn.id AND crm.member_type='Node' 
       WHERE #{OSM.sql_for_area(ymin, xmin, ymax, xmax, "cn.")}
      EOF
    unless way_ids.empty?
      sql+=<<-EOF
       UNION
        SELECT DISTINCT cr.id AS relid,cr.version AS version
        FROM current_relations cr
        INNER JOIN current_relation_members crm ON crm.id=cr.id
         WHERE crm.member_type='Way' 
         AND crm.member_id IN (#{way_ids.join(',')})
        EOF
    end
    ActiveRecord::Base.connection.select_all(sql).collect { |a| [a['relid'].to_i,a['version'].to_i] }
  end
	
  def sql_get_nodes_in_way(wayid)
    points=[]
    sql=<<-EOF
      SELECT latitude*0.0000001 AS lat,longitude*0.0000001 AS lon,current_nodes.id,current_nodes.version 
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
      points << [row['lon'].to_f,row['lat'].to_f,row['id'].to_i,nodetags,row['version'].to_i]
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

