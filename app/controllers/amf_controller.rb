# amf_controller is a semi-standalone API for Flash clients, particularly
# Potlatch. All interaction between Potlatch (as a .SWF application) and the
# OSM database takes place using this controller. Messages are
# encoded in the Actionscript Message Format (AMF).
#
# Helper functions are in /lib/potlatch.rb
#
# Author::  editions Systeme D / Richard Fairhurst 2004-2008
# Licence:: public domain.
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
# return(-1,"message")        <-- just puts up a dialogue
# return(-2,"message")        <-- also asks the user to e-mail me
# return(-3,["type",v],id)    <-- version conflict
# return(-4,"type",id)        <-- object not found
# -5 indicates the method wasn't called (due to a previous error)
#
# To write to the Rails log, use logger.info("message").

# Remaining issues:
# * version conflict when POIs and ways are reverted

class AmfController < ApplicationController
  include Potlatch

  skip_before_action :verify_authenticity_token
  before_action :check_api_writable

  # Main AMF handlers: process the raw AMF string (using AMF library) and
  # calls each action (private method) accordingly.

  def amf_read
    self.status = :ok
    self.content_type = Mime::AMF
    self.response_body = Dispatcher.new(request.raw_post) do |message, *args|
      logger.info("Executing AMF #{message}(#{args.join(',')})")

      case message
      when "getpresets" then        result = getpresets(*args)
      when "whichways" then         result = whichways(*args)
      when "whichways_deleted" then result = whichways_deleted(*args)
      when "getway" then            result = getway(args[0].to_i)
      when "getrelation" then       result = getrelation(args[0].to_i)
      when "getway_old" then        result = getway_old(args[0].to_i, args[1])
      when "getway_history" then    result = getway_history(args[0].to_i)
      when "getnode_history" then   result = getnode_history(args[0].to_i)
      when "findgpx" then           result = findgpx(*args)
      when "findrelations" then     result = findrelations(*args)
      when "getpoi" then            result = getpoi(*args)
      end

      result
    end
  end

  def amf_write
    renumberednodes = {}              # Shared across repeated putways
    renumberedways = {}               # Shared across repeated putways
    err = false                       # Abort batch on error

    self.status = :ok
    self.content_type = Mime::AMF
    self.response_body = Dispatcher.new(request.raw_post) do |message, *args|
      logger.info("Executing AMF #{message}")

      if err
        result = [-5, nil]
      else
        case message
        when "putway" then
          orn = renumberednodes.dup
          result = putway(renumberednodes, *args)
          result[4] = renumberednodes.reject { |k, _v| orn.key?(k) }
          renumberedways[result[2]] = result[3] if result[0].zero? && result[2] != result[3]
        when "putrelation" then
          result = putrelation(renumberednodes, renumberedways, *args)
        when "deleteway" then
          result = deleteway(*args)
        when "putpoi" then
          result = putpoi(*args)
          renumberednodes[result[2]] = result[3] if result[0].zero? && result[2] != result[3]
        when "startchangeset" then
          result = startchangeset(*args)
        end

        err = true if result[0] == -3 # If a conflict is detected, don't execute any more writes
      end

      result
    end
  end

  private

  def amf_handle_error(call, rootobj, rootid)
    yield
  rescue OSM::APIAlreadyDeletedError => ex
    return [-4, ex.object, ex.object_id]
  rescue OSM::APIVersionMismatchError => ex
    return [-3, [rootobj, rootid], [ex.type.downcase, ex.id, ex.latest]]
  rescue OSM::APIUserChangesetMismatchError => ex
    return [-2, ex.to_s]
  rescue OSM::APIBadBoundingBox => ex
    return [-2, "Sorry - I can't get the map for that area. The server said: #{ex}"]
  rescue OSM::APIError => ex
    return [-1, ex.to_s]
  rescue StandardError => ex
    return [-2, "An unusual error happened (in #{call}). The server said: #{ex}"]
  end

  def amf_handle_error_with_timeout(call, rootobj, rootid)
    amf_handle_error(call, rootobj, rootid) do
      OSM::Timer.timeout(API_TIMEOUT, OSM::APITimeoutError) do
        yield
      end
    end
  end

  # Start new changeset
  # Returns success_code,success_message,changeset id

  def startchangeset(usertoken, cstags, closeid, closecomment, opennew)
    amf_handle_error("'startchangeset'", nil, nil) do
      user = getuser(usertoken)
      return -1, "You are not logged in, so Potlatch can't write any changes to the database." unless user
      return -1, t("application.setup_user_auth.blocked") if user.blocks.active.exists?
      return -1, "You must accept the contributor terms before you can edit." if REQUIRE_TERMS_AGREED && user.terms_agreed.nil?

      if cstags
        return -1, "One of the tags is invalid. Linux users may need to upgrade to Flash Player 10.1." unless tags_ok(cstags)
        cstags = strip_non_xml_chars cstags
      end

      # close previous changeset and add comment
      if closeid
        cs = Changeset.find(closeid.to_i)
        cs.set_closed_time_now
        if cs.user_id != user.id
          raise OSM::APIUserChangesetMismatchError.new
        elsif closecomment.empty?
          cs.save!
        else
          cs.tags["comment"] = closecomment
          # in case closecomment has chars not allowed in xml
          cs.tags = strip_non_xml_chars cs.tags
          cs.save_with_tags!
        end
      end

      # open a new changeset
      if opennew.nonzero?
        cs = Changeset.new
        cs.tags = cstags
        cs.user_id = user.id
        unless closecomment.empty?
          cs.tags["comment"] = closecomment
          # in case closecomment has chars not allowed in xml
          cs.tags = strip_non_xml_chars cs.tags
        end
        # smsm1 doesn't like the next two lines and thinks they need to be abstracted to the model more/better
        cs.created_at = Time.now.getutc
        cs.closed_at = cs.created_at + Changeset::IDLE_TIMEOUT
        cs.save_with_tags!
        return [0, "", cs.id]
      else
        return [0, "", nil]
      end
    end
  end

  # Return presets (default tags, localisation etc.):
  # uses POTLATCH_PRESETS global, set up in OSM::Potlatch.

  def getpresets(usertoken, lang) #:doc:
    user = getuser(usertoken)

    langs = if user && !user.languages.empty?
              Locale.list(user.languages)
            else
              Locale.list(http_accept_language.user_preferred_languages)
            end

    lang = getlocales.preferred(langs)
    (real_lang, localised) = getlocalized(lang.to_s)

    # Tell Potlatch what language it's using
    localised["__potlatch_locale"] = real_lang

    # Get help from i18n but delete it so we won't pass it around
    # twice for nothing
    help = localised["help_html"]
    localised.delete("help_html")

    # Populate icon names
    POTLATCH_PRESETS[10].each do |id|
      POTLATCH_PRESETS[11][id] = localised["preset_icon_#{id}"]
      localised.delete("preset_icon_#{id}")
    end

    POTLATCH_PRESETS + [localised, help]
  end

  def getlocalized(lang)
    # What we end up actually using. Reported in Potlatch's created_by=* string
    loaded_lang = "en"

    # Load English defaults
    en = YAML.load(File.open("#{Rails.root}/config/potlatch/locales/en.yml"))["en"]

    if lang == "en"
      return [loaded_lang, en]
    else
      # Use English as a fallback
      begin
        other = YAML.load(File.open("#{Rails.root}/config/potlatch/locales/#{lang}.yml"))[lang]
        loaded_lang = lang
      rescue
        other = en
      end

      # We have to return a flat list and some of the keys won't be
      # translated (probably)
      return [loaded_lang, en.merge(other)]
    end
  end

  ##
  # Find all the ways, POI nodes (i.e. not part of ways), and relations
  # in a given bounding box. Nodes are returned in full; ways and relations
  # are IDs only.
  #
  # return is of the form:
  # [success_code, success_message,
  #  [[way_id, way_version], ...],
  #  [[node_id, lat, lon, [tags, ...], node_version], ...],
  #  [[rel_id, rel_version], ...]]
  # where the ways are any visible ways which refer to any visible
  # nodes in the bbox, nodes are any visible nodes in the bbox but not
  # used in any way, rel is any relation which refers to either a way
  # or node that we're returning.
  def whichways(xmin, ymin, xmax, ymax) #:doc:
    amf_handle_error_with_timeout("'whichways'", nil, nil) do
      enlarge = [(xmax - xmin) / 8, 0.01].min
      xmin -= enlarge
      ymin -= enlarge
      xmax += enlarge
      ymax += enlarge

      # check boundary is sane and area within defined
      # see /config/application.yml
      bbox = BoundingBox.new(xmin, ymin, xmax, ymax)
      bbox.check_boundaries
      bbox.check_size

      if POTLATCH_USE_SQL
        ways = sql_find_ways_in_area(bbox)
        points = sql_find_pois_in_area(bbox)
        relations = sql_find_relations_in_area_and_ways(bbox, ways.collect { |x| x[0] })
      else
        # find the way ids in an area
        nodes_in_area = Node.bbox(bbox).visible.includes(:ways)
        ways = nodes_in_area.inject([]) do |sum, node|
          visible_ways = node.ways.select(&:visible?)
          sum + visible_ways.collect { |w| [w.id, w.version] }
        end.uniq
        ways.delete([])

        # find the node ids in an area that aren't part of ways
        nodes_not_used_in_area = nodes_in_area.select { |node| node.ways.empty? }
        points = nodes_not_used_in_area.collect { |n| [n.id, n.lon, n.lat, n.tags, n.version] }.uniq

        # find the relations used by those nodes and ways
        relations = Relation.nodes(nodes_in_area.collect(&:id)).visible +
                    Relation.ways(ways.collect { |w| w[0] }).visible
        relations = relations.collect { |relation| [relation.id, relation.version] }.uniq
      end

      [0, "", ways, points, relations]
    end
  end

  # Find deleted ways in current bounding box (similar to whichways, but ways
  # with a deleted node only - not POIs or relations).

  def whichways_deleted(xmin, ymin, xmax, ymax) #:doc:
    amf_handle_error_with_timeout("'whichways_deleted'", nil, nil) do
      enlarge = [(xmax - xmin) / 8, 0.01].min
      xmin -= enlarge
      ymin -= enlarge
      xmax += enlarge
      ymax += enlarge

      # check boundary is sane and area within defined
      # see /config/application.yml
      bbox = BoundingBox.new(xmin, ymin, xmax, ymax)
      bbox.check_boundaries
      bbox.check_size

      nodes_in_area = Node.bbox(bbox).joins(:ways_via_history).where(:current_ways => { :visible => false })
      way_ids = nodes_in_area.collect { |node| node.ways_via_history.invisible.collect(&:id) }.flatten.uniq

      [0, "", way_ids]
    end
  end

  # Get a way including nodes and tags.
  # Returns the way id, a Potlatch-style array of points, a hash of tags, the version number, and the user ID.

  def getway(wayid) #:doc:
    amf_handle_error_with_timeout("'getway' #{wayid}", "way", wayid) do
      if POTLATCH_USE_SQL
        points = sql_get_nodes_in_way(wayid)
        tags = sql_get_tags_in_way(wayid)
        version = sql_get_way_version(wayid)
        uid = sql_get_way_user(wayid)
      else
        # Ideally we would do ":include => :nodes" here but if we do that
        # then rails only seems to return the first copy of a node when a
        # way includes a node more than once
        way = Way.where(:id => wayid).first

        # check case where way has been deleted or doesn't exist
        return [-4, "way", wayid] if way.nil? || !way.visible

        points = way.nodes.preload(:node_tags).collect do |node|
          nodetags = node.tags
          nodetags.delete("created_by")
          [node.lon, node.lat, node.id, nodetags, node.version]
        end
        tags = way.tags
        version = way.version
        uid = way.changeset.user.id
      end

      [0, "", wayid, points, tags, version, uid]
    end
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
    amf_handle_error_with_timeout("'getway_old' #{id}, #{timestamp}", "way", id) do
      if timestamp == ""
        # undelete
        old_way = OldWay.where(:visible => true, :way_id => id).unredacted.order("version DESC").first
        points = old_way.get_nodes_undelete unless old_way.nil?
      else
        begin
          # revert
          timestamp = DateTime.strptime(timestamp.to_s, "%d %b %Y, %H:%M:%S")
          old_way = OldWay.where("way_id = ? AND timestamp <= ?", id, timestamp).unredacted.order("timestamp DESC").first
          unless old_way.nil?
            if old_way.visible
              points = old_way.get_nodes_revert(timestamp)
            else
              return [-1, "Sorry, the way was deleted at that time - please revert to a previous version.", id]
            end
          end
        rescue ArgumentError
          # thrown by date parsing method. leave old_way as nil for
          # the error handler below.
          old_way = nil
        end
      end

      if old_way.nil?
        return [-1, "Sorry, the server could not find a way at that time.", id]
      else
        curway = Way.find(id)
        old_way.tags["history"] = "Retrieved from v#{old_way.version}"
        return [0, "", id, points, old_way.tags, curway.version, (curway.version == old_way.version && curway.visible)]
      end
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
    revdates = []
    revusers = {}
    Way.find(wayid).old_ways.unredacted.collect do |a|
      revdates.push(a.timestamp)
      revusers[a.timestamp.to_i] = change_user(a) unless revusers.key?(a.timestamp.to_i)
      a.nds.each do |n|
        Node.find(n).old_nodes.unredacted.collect do |o|
          revdates.push(o.timestamp)
          revusers[o.timestamp.to_i] = change_user(o) unless revusers.key?(o.timestamp.to_i)
        end
      end
    end
    waycreated = revdates[0]
    revdates.uniq!
    revdates.sort!
    revdates.reverse!

    # Remove any dates (from nodes) before first revision date of way
    revdates.delete_if { |d| d < waycreated }
    # Remove any elements where 2 seconds doesn't elapse before next one
    revdates.delete_if { |d| revdates.include?(d + 1) || revdates.include?(d + 2) }
    # Collect all in one nested array
    revdates.collect! { |d| [(d + 1).strftime("%d %b %Y, %H:%M:%S")] + revusers[d.to_i] }
    revdates.uniq!

    return ["way", wayid, revdates]
  rescue ActiveRecord::RecordNotFound
    return ["way", wayid, []]
  end

  # Find history of a node. Returns 'node', id, and an array of previous versions as above.

  def getnode_history(nodeid) #:doc:
    history = Node.find(nodeid).old_nodes.unredacted.reverse.collect do |old_node|
      [(old_node.timestamp + 1).strftime("%d %b %Y, %H:%M:%S")] + change_user(old_node)
    end
    return ["node", nodeid, history]
  rescue ActiveRecord::RecordNotFound
    return ["node", nodeid, []]
  end

  def change_user(obj)
    user_object = obj.changeset.user
    user = user_object.data_public? ? user_object.display_name : "anonymous"
    uid  = user_object.data_public? ? user_object.id : 0
    [user, uid]
  end

  # Find GPS traces with specified name/id.
  # Returns array listing GPXs, each one comprising id, name and description.

  def findgpx(searchterm, usertoken)
    amf_handle_error_with_timeout("'findgpx'", nil, nil) do
      user = getuser(usertoken)

      return -1, "You must be logged in to search for GPX traces." unless user
      return -1, t("application.setup_user_auth.blocked") if user.blocks.active.exists?

      query = Trace.visible_to(user)
      query = if searchterm.to_i > 0
                query.where(:id => searchterm.to_i)
              else
                query.where("MATCH(name) AGAINST (?)", searchterm).limit(21)
              end
      gpxs = query.collect do |gpx|
        [gpx.id, gpx.name, gpx.description]
      end
      [0, "", gpxs]
    end
  end

  # Get a relation with all tags and members.
  # Returns:
  # 0. success code?
  # 1. object type?
  # 2. relation id,
  # 3. hash of tags,
  # 4. list of members,
  # 5. version.

  def getrelation(relid) #:doc:
    amf_handle_error("'getrelation' #{relid}", "relation", relid) do
      rel = Relation.where(:id => relid).first

      return [-4, "relation", relid] if rel.nil? || !rel.visible
      [0, "", relid, rel.tags, rel.members, rel.version]
    end
  end

  # Find relations with specified name/id.
  # Returns array of relations, each in same form as getrelation.

  def findrelations(searchterm)
    rels = []
    if searchterm.to_i > 0
      rel = Relation.where(:id => searchterm.to_i).first
      if rel && rel.visible
        rels.push([rel.id, rel.tags, rel.members, rel.version])
      end
    else
      RelationTag.where("v like ?", "%#{searchterm}%").limit(11).each do |t|
        if t.relation.visible
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
    amf_handle_error("'putrelation' #{relid}", "relation", relid) do
      user = getuser(usertoken)

      return -1, "You are not logged in, so the relation could not be saved." unless user
      return -1, t("application.setup_user_auth.blocked") if user.blocks.active.exists?
      return -1, "You must accept the contributor terms before you can edit." if REQUIRE_TERMS_AGREED && user.terms_agreed.nil?

      return -1, "One of the tags is invalid. Linux users may need to upgrade to Flash Player 10.1." unless tags_ok(tags)
      tags = strip_non_xml_chars tags

      relid = relid.to_i
      visible = visible.to_i.nonzero?

      new_relation = nil
      relation = nil
      Relation.transaction do
        # create a new relation, or find the existing one
        relation = Relation.find(relid) if relid > 0
        # We always need a new node, based on the data that has been sent to us
        new_relation = Relation.new

        # check the members are all positive, and correctly type
        typedmembers = []
        members.each do |m|
          mid = m[1].to_i
          if mid < 0
            mid = renumberednodes[mid] if m[0] == "Node"
            mid = renumberedways[mid] if m[0] == "Way"
          end
          if mid
            typedmembers << [m[0], mid, m[2].delete("\000-\037\ufffe\uffff", "^\011\012\015")]
          end
        end

        # assign new contents
        new_relation.members = typedmembers
        new_relation.tags = tags
        new_relation.visible = visible
        new_relation.changeset_id = changeset_id
        new_relation.version = version

        if relid <= 0
          # We're creating the relation
          new_relation.create_with_history(user)
        elsif visible
          # We're updating the relation
          new_relation.id = relid
          relation.update_from(new_relation, user)
        else
          # We're deleting the relation
          new_relation.id = relid
          relation.delete_with_history!(new_relation, user)
        end
      end # transaction

      if relid <= 0
        return [0, "", relid, new_relation.id, new_relation.version]
      else
        return [0, "", relid, relid, relation.version]
      end
    end
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
  # 7. array of nodes to change (each one is [lon,lat,id,version,tags]),
  # 8. hash of nodes to delete (id->version).
  #
  # Returns:
  # 0. '0' (code for success),
  # 1. message,
  # 2. original way id (unchanged),
  # 3. new way id,
  # 4. hash of renumbered nodes (old id=>new id),
  # 5. way version,
  # 6. hash of changed node versions (node=>version)
  # 7. hash of deleted node versions (node=>version)

  def putway(renumberednodes, usertoken, changeset_id, wayversion, originalway, pointlist, attributes, nodes, deletednodes) #:doc:
    amf_handle_error("'putway' #{originalway}", "way", originalway) do
      # -- Initialise

      user = getuser(usertoken)
      return -1, "You are not logged in, so the way could not be saved." unless user
      return -1, t("application.setup_user_auth.blocked") if user.blocks.active.exists?
      return -1, "You must accept the contributor terms before you can edit." if REQUIRE_TERMS_AGREED && user.terms_agreed.nil?

      return -2, "Server error - way is only #{pointlist.length} points long." if pointlist.length < 2

      return -1, "One of the tags is invalid. Linux users may need to upgrade to Flash Player 10.1." unless tags_ok(attributes)
      attributes = strip_non_xml_chars attributes

      originalway = originalway.to_i
      pointlist.collect!(&:to_i)

      way = nil # this is returned, so scope it outside the transaction
      nodeversions = {}
      Way.transaction do
        # -- Update each changed node

        nodes.each do |a|
          lon = a[0].to_f
          lat = a[1].to_f
          id = a[2].to_i
          version = a[3].to_i

          return -2, "Server error - node with id 0 found in way #{originalway}." if id.zero?
          return -2, "Server error - node with latitude -90 found in way #{originalway}." if lat == 90

          id = renumberednodes[id] if renumberednodes[id]

          node = Node.new
          node.changeset_id = changeset_id
          node.lat = lat
          node.lon = lon
          node.tags = a[4]

          # fixup node tags in a way as well
          return -1, "One of the tags is invalid. Linux users may need to upgrade to Flash Player 10.1." unless tags_ok(node.tags)
          node.tags = strip_non_xml_chars node.tags

          node.tags.delete("created_by")
          node.version = version
          if id <= 0
            # We're creating the node
            node.create_with_history(user)
            renumberednodes[id] = node.id
            nodeversions[node.id] = node.version
          else
            # We're updating an existing node
            previous = Node.find(id)
            node.id = id
            previous.update_from(node, user)
            nodeversions[previous.id] = previous.version
          end
        end

        # -- Save revised way

        pointlist.collect! do |a|
          renumberednodes[a] ? renumberednodes[a] : a
        end # renumber nodes
        new_way = Way.new
        new_way.tags = attributes
        new_way.nds = pointlist
        new_way.changeset_id = changeset_id
        new_way.version = wayversion
        if originalway <= 0
          new_way.create_with_history(user)
          way = new_way # so we can get way.id and way.version
        else
          way = Way.find(originalway)
          if way.tags != attributes || way.nds != pointlist || !way.visible?
            new_way.id = originalway
            way.update_from(new_way, user)
          end
        end

        # -- Delete unwanted nodes

        deletednodes.each do |id, v|
          node = Node.find(id.to_i)
          new_node = Node.new
          new_node.changeset_id = changeset_id
          new_node.version = v.to_i
          new_node.id = id.to_i
          begin
            node.delete_with_history!(new_node, user)
          rescue OSM::APIPreconditionFailedError
            # We don't do anything here as the node is being used elsewhere
            # and we don't want to delete it
          end
        end
      end # transaction

      [0, "", originalway, way.id, renumberednodes, way.version, nodeversions, deletednodes]
    end
  end

  # Save POI to the database.
  # Refuses save if the node has since become part of a way.
  # Returns array with:
  # 0. 0 (success),
  # 1. success message,
  # 2. original node id (unchanged),
  # 3. new node id,
  # 4. version.

  def putpoi(usertoken, changeset_id, version, id, lon, lat, tags, visible) #:doc:
    amf_handle_error("'putpoi' #{id}", "node", id) do
      user = getuser(usertoken)
      return -1, "You are not logged in, so the point could not be saved." unless user
      return -1, t("application.setup_user_auth.blocked") if user.blocks.active.exists?
      return -1, "You must accept the contributor terms before you can edit." if REQUIRE_TERMS_AGREED && user.terms_agreed.nil?

      return -1, "One of the tags is invalid. Linux users may need to upgrade to Flash Player 10.1." unless tags_ok(tags)
      tags = strip_non_xml_chars tags

      id = id.to_i
      visible = (visible.to_i == 1)
      node = nil
      new_node = nil
      Node.transaction do
        if id > 0
          begin
            node = Node.find(id)
          rescue ActiveRecord::RecordNotFound
            return [-4, "node", id]
          end

          unless visible || node.ways.empty?
            return -1, "Point #{id} has since become part of a way, so you cannot save it as a POI.", id, id, version
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
          new_node.id = id
          node.update_from(new_node, user)
        else
          # We're deleting the node
          new_node.id = id
          node.delete_with_history!(new_node, user)
        end
      end # transaction

      if id <= 0
        return [0, "", id, new_node.id, new_node.version]
      else
        return [0, "", id, node.id, node.version]
      end
    end
  end

  # Read POI from database
  # (only called on revert: POIs are usually read by whichways).
  #
  # Returns array of id, long, lat, hash of tags, (current) version.

  def getpoi(id, timestamp) #:doc:
    amf_handle_error("'getpoi' #{id}", "node", id) do
      id = id.to_i
      n = Node.where(:id => id).first
      if n
        v = n.version
        unless timestamp == ""
          n = OldNode.where("node_id = ? AND timestamp <= ?", id, timestamp).unredacted.order("timestamp DESC").first
        end
      end

      if n
        return [0, "", id, n.lon, n.lat, n.tags, v]
      else
        return [-4, "node", id]
      end
    end
  end

  # Delete way and all constituent nodes.
  # Params:
  # * The user token
  # * the changeset id
  # * the id of the way to change
  # * the version of the way that was downloaded
  # * a hash of the id and versions of all the nodes that are in the way, if any
  # of the nodes have been changed by someone else then, there is a problem!
  # Returns 0 (success), unchanged way id, new way version, new node versions.

  def deleteway(usertoken, changeset_id, way_id, way_version, deletednodes) #:doc:
    amf_handle_error("'deleteway' #{way_id}", "way", way_id) do
      user = getuser(usertoken)
      return -1, "You are not logged in, so the way could not be deleted." unless user
      return -1, t("application.setup_user_auth.blocked") if user.blocks.active.exists?
      return -1, "You must accept the contributor terms before you can edit." if REQUIRE_TERMS_AGREED && user.terms_agreed.nil?

      way_id = way_id.to_i
      nodeversions = {}
      old_way = nil # returned, so scope it outside the transaction
      # Need a transaction so that if one item fails to delete, the whole delete fails.
      Way.transaction do
        # -- Delete the way

        old_way = Way.find(way_id)
        delete_way = Way.new
        delete_way.version = way_version
        delete_way.changeset_id = changeset_id
        delete_way.id = way_id
        old_way.delete_with_history!(delete_way, user)

        # -- Delete unwanted nodes

        deletednodes.each do |id, v|
          node = Node.find(id.to_i)
          new_node = Node.new
          new_node.changeset_id = changeset_id
          new_node.version = v.to_i
          new_node.id = id.to_i
          begin
            node.delete_with_history!(new_node, user)
            nodeversions[node.id] = node.version
          rescue OSM::APIPreconditionFailedError
            # We don't do anything with the exception as the node is in use
            # elsewhere and we don't want to delete it
          end
        end
      end # transaction
      [0, "", way_id, old_way.version, nodeversions]
    end
  end

  # ====================================================================
  # Support functions

  # Authenticate token
  # (can also be of form user:pass)
  # When we are writing to the api, we need the actual user model,
  # not just the id, hence this abstraction

  def getuser(token) #:doc:
    if token =~ /^(.+)\:(.+)$/
      User.authenticate(:username => $1, :password => $2)
    else
      User.authenticate(:token => token)
    end
  end

  def getlocales
    @locales ||= Locale.list(Dir.glob("#{Rails.root}/config/potlatch/locales/*").collect { |f| File.basename(f, ".yml") })
  end

  ##
  # check that all key-value pairs are valid UTF-8.
  def tags_ok(tags)
    tags.each do |k, v|
      return false unless UTF8.valid? k
      return false unless UTF8.valid? v
    end
    true
  end

  ##
  # strip characters which are invalid in XML documents from the strings
  # in the +tags+ hash.
  def strip_non_xml_chars(tags)
    new_tags = {}
    unless tags.nil?
      tags.each do |k, v|
        new_k = k.delete "\000-\037\ufffe\uffff", "^\011\012\015"
        new_v = v.delete "\000-\037\ufffe\uffff", "^\011\012\015"
        new_tags[new_k] = new_v
      end
    end
    new_tags
  end

  # ====================================================================
  # Alternative SQL queries for getway/whichways

  def sql_find_ways_in_area(bbox)
    sql = <<-EOF
    SELECT DISTINCT current_ways.id AS wayid,current_ways.version AS version
      FROM current_way_nodes
    INNER JOIN current_nodes ON current_nodes.id=current_way_nodes.node_id
    INNER JOIN current_ways  ON current_ways.id =current_way_nodes.id
       WHERE current_nodes.visible=TRUE
       AND current_ways.visible=TRUE
       AND #{OSM.sql_for_area(bbox, "current_nodes.")}
    EOF
    ActiveRecord::Base.connection.select_all(sql).collect { |a| [a["wayid"].to_i, a["version"].to_i] }
  end

  def sql_find_pois_in_area(bbox)
    pois = []
    sql = <<-EOF
      SELECT current_nodes.id,current_nodes.latitude*0.0000001 AS lat,current_nodes.longitude*0.0000001 AS lon,current_nodes.version
      FROM current_nodes
       LEFT OUTER JOIN current_way_nodes cwn ON cwn.node_id=current_nodes.id
       WHERE current_nodes.visible=TRUE
       AND cwn.id IS NULL
       AND #{OSM.sql_for_area(bbox, "current_nodes.")}
    EOF
    ActiveRecord::Base.connection.select_all(sql).each do |row|
      poitags = {}
      ActiveRecord::Base.connection.select_all("SELECT k,v FROM current_node_tags WHERE id=#{row['id']}").each do |n|
        poitags[n["k"]] = n["v"]
      end
      pois << [row["id"].to_i, row["lon"].to_f, row["lat"].to_f, poitags, row["version"].to_i]
    end
    pois
  end

  def sql_find_relations_in_area_and_ways(bbox, way_ids)
    # ** It would be more Potlatchy to get relations for nodes within ways
    #    during 'getway', not here
    sql = <<-EOF
      SELECT DISTINCT cr.id AS relid,cr.version AS version
      FROM current_relations cr
      INNER JOIN current_relation_members crm ON crm.id=cr.id
      INNER JOIN current_nodes cn ON crm.member_id=cn.id AND crm.member_type='Node'
       WHERE #{OSM.sql_for_area(bbox, "cn.")}
      EOF
    unless way_ids.empty?
      sql += <<-EOF
       UNION
        SELECT DISTINCT cr.id AS relid,cr.version AS version
        FROM current_relations cr
        INNER JOIN current_relation_members crm ON crm.id=cr.id
         WHERE crm.member_type='Way'
         AND crm.member_id IN (#{way_ids.join(',')})
        EOF
    end
    ActiveRecord::Base.connection.select_all(sql).collect { |a| [a["relid"].to_i, a["version"].to_i] }
  end

  def sql_get_nodes_in_way(wayid)
    points = []
    sql = <<-EOF
      SELECT latitude*0.0000001 AS lat,longitude*0.0000001 AS lon,current_nodes.id,current_nodes.version
      FROM current_way_nodes,current_nodes
       WHERE current_way_nodes.id=#{wayid.to_i}
       AND current_way_nodes.node_id=current_nodes.id
       AND current_nodes.visible=TRUE
      ORDER BY sequence_id
    EOF
    ActiveRecord::Base.connection.select_all(sql).each do |row|
      nodetags = {}
      ActiveRecord::Base.connection.select_all("SELECT k,v FROM current_node_tags WHERE id=#{row['id']}").each do |n|
        nodetags[n["k"]] = n["v"]
      end
      nodetags.delete("created_by")
      points << [row["lon"].to_f, row["lat"].to_f, row["id"].to_i, nodetags, row["version"].to_i]
    end
    points
  end

  def sql_get_tags_in_way(wayid)
    tags = {}
    ActiveRecord::Base.connection.select_all("SELECT k,v FROM current_way_tags WHERE id=#{wayid.to_i}").each do |row|
      tags[row["k"]] = row["v"]
    end
    tags
  end

  def sql_get_way_version(wayid)
    ActiveRecord::Base.connection.select_one("SELECT version FROM current_ways WHERE id=#{wayid.to_i}")["version"]
  end

  def sql_get_way_user(wayid)
    ActiveRecord::Base.connection.select_one("SELECT user FROM current_ways,changesets WHERE current_ways.id=#{wayid.to_i} AND current_ways.changeset=changesets.id")["user"]
  end
end
