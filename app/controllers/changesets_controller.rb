# The ChangesetController is the RESTful interface to Changeset objects

class ChangesetsController < ApplicationController
  layout "site"
  require "xml/libxml"

  skip_before_action :verify_authenticity_token, :except => [:index]
  before_action :authorize_web, :only => [:index, :feed]
  before_action :set_locale, :only => [:index, :feed]
  before_action :authorize, :only => [:create, :update, :upload, :close, :subscribe, :unsubscribe]
  before_action :api_deny_access_handler, :only => [:create, :update, :upload, :close, :subscribe, :unsubscribe, :expand_bbox]

  authorize_resource

  before_action :require_public_data, :only => [:create, :update, :upload, :close, :subscribe, :unsubscribe]
  before_action :check_api_writable, :only => [:create, :update, :upload, :subscribe, :unsubscribe]
  before_action :check_api_readable, :except => [:create, :update, :upload, :download, :query, :index, :feed, :subscribe, :unsubscribe]
  before_action(:only => [:index, :feed]) { |c| c.check_database_readable(true) }
  around_action :api_call_handle_error, :except => [:index, :feed]
  around_action :api_call_timeout, :except => [:index, :feed, :upload]
  around_action :web_timeout, :only => [:index, :feed]

  # Helper methods for checking consistency
  include ConsistencyValidations

  # Create a changeset from XML.
  def create
    assert_method :put

    cs = Changeset.from_xml(request.raw_post, true)

    # Assume that Changeset.from_xml has thrown an exception if there is an error parsing the xml
    cs.user = current_user
    cs.save_with_tags!

    # Subscribe user to changeset comments
    cs.subscribers << current_user

    render :plain => cs.id.to_s
  end

  ##
  # Return XML giving the basic info about the changeset. Does not
  # return anything about the nodes, ways and relations in the changeset.
  def read
    changeset = Changeset.find(params[:id])

    render :xml => changeset.to_xml(params[:include_discussion].presence).to_s
  end

  ##
  # marks a changeset as closed. this may be called multiple times
  # on the same changeset, so is idempotent.
  def close
    assert_method :put

    changeset = Changeset.find(params[:id])
    check_changeset_consistency(changeset, current_user)

    # to close the changeset, we'll just set its closed_at time to
    # now. this might not be enough if there are concurrency issues,
    # but we'll have to wait and see.
    changeset.set_closed_time_now

    changeset.save!
    head :ok
  end

  ##
  # insert a (set of) points into a changeset bounding box. this can only
  # increase the size of the bounding box. this is a hint that clients can
  # set either before uploading a large number of changes, or changes that
  # the client (but not the server) knows will affect areas further away.
  def expand_bbox
    # only allow POST requests, because although this method is
    # idempotent, there is no "document" to PUT really...
    assert_method :post

    cs = Changeset.find(params[:id])
    check_changeset_consistency(cs, current_user)

    # keep an array of lons and lats
    lon = []
    lat = []

    # the request is in pseudo-osm format... this is kind-of an
    # abuse, maybe should change to some other format?
    doc = XML::Parser.string(request.raw_post, :options => XML::Parser::Options::NOERROR).parse
    doc.find("//osm/node").each do |n|
      lon << n["lon"].to_f * GeoRecord::SCALE
      lat << n["lat"].to_f * GeoRecord::SCALE
    end

    # add the existing bounding box to the lon-lat array
    lon << cs.min_lon unless cs.min_lon.nil?
    lat << cs.min_lat unless cs.min_lat.nil?
    lon << cs.max_lon unless cs.max_lon.nil?
    lat << cs.max_lat unless cs.max_lat.nil?

    # collapse the arrays to minimum and maximum
    cs.min_lon = lon.min
    cs.min_lat = lat.min
    cs.max_lon = lon.max
    cs.max_lat = lat.max

    # save the larger bounding box and return the changeset, which
    # will include the bigger bounding box.
    cs.save!
    render :xml => cs.to_xml.to_s
  end

  ##
  # Upload a diff in a single transaction.
  #
  # This means that each change within the diff must succeed, i.e: that
  # each version number mentioned is still current. Otherwise the entire
  # transaction *must* be rolled back.
  #
  # Furthermore, each element in the diff can only reference the current
  # changeset.
  #
  # Returns: a diffResult document, as described in
  # http://wiki.openstreetmap.org/wiki/OSM_Protocol_Version_0.6
  def upload
    # only allow POST requests, as the upload method is most definitely
    # not idempotent, as several uploads with placeholder IDs will have
    # different side-effects.
    # see http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.1.2
    assert_method :post

    changeset = Changeset.find(params[:id])
    check_changeset_consistency(changeset, current_user)

    diff_reader = DiffReader.new(request.raw_post, changeset)
    Changeset.transaction do
      result = diff_reader.commit
      render :xml => result.to_s
    end
  end

  ##
  # download the changeset as an osmChange document.
  #
  # to make it easier to revert diffs it would be better if the osmChange
  # format were reversible, i.e: contained both old and new versions of
  # modified elements. but it doesn't at the moment...
  #
  # this method cannot order the database changes fully (i.e: timestamp and
  # version number may be too coarse) so the resulting diff may not apply
  # to a different database. however since changesets are not atomic this
  # behaviour cannot be guaranteed anyway and is the result of a design
  # choice.
  def download
    changeset = Changeset.find(params[:id])

    # get all the elements in the changeset which haven't been redacted
    # and stick them in a big array.
    elements = [changeset.old_nodes.unredacted,
                changeset.old_ways.unredacted,
                changeset.old_relations.unredacted].flatten

    # sort the elements by timestamp and version number, as this is the
    # almost sensible ordering available. this would be much nicer if
    # global (SVN-style) versioning were used - then that would be
    # unambiguous.
    elements.sort! do |a, b|
      if a.timestamp == b.timestamp
        a.version <=> b.version
      else
        a.timestamp <=> b.timestamp
      end
    end

    # create changeset and user caches
    changeset_cache = {}
    user_display_name_cache = {}

    # create an osmChange document for the output
    result = OSM::API.new.get_xml_doc
    result.root.name = "osmChange"

    # generate an output element for each operation. note: we avoid looking
    # at the history because it is simpler - but it would be more correct to
    # check these assertions.
    elements.each do |elt|
      result.root <<
        if elt.version == 1
          # first version, so it must be newly-created.
          created = XML::Node.new "create"
          created << elt.to_xml_node(changeset_cache, user_display_name_cache)
        elsif elt.visible
          # must be a modify
          modified = XML::Node.new "modify"
          modified << elt.to_xml_node(changeset_cache, user_display_name_cache)
        else
          # if the element isn't visible then it must have been deleted
          deleted = XML::Node.new "delete"
          deleted << elt.to_xml_node(changeset_cache, user_display_name_cache)
        end
    end

    render :xml => result.to_s
  end

  ##
  # query changesets by bounding box, time, user or open/closed status.
  def query
    # find any bounding box
    bbox = BoundingBox.from_bbox_params(params) if params["bbox"]

    # create the conditions that the user asked for. some or all of
    # these may be nil.
    changesets = Changeset.all
    changesets = conditions_bbox(changesets, bbox)
    changesets = conditions_user(changesets, params["user"], params["display_name"])
    changesets = conditions_time(changesets, params["time"])
    changesets = conditions_open(changesets, params["open"])
    changesets = conditions_closed(changesets, params["closed"])
    changesets = conditions_ids(changesets, params["changesets"])

    # sort and limit the changesets
    changesets = changesets.order("created_at DESC").limit(100)

    # preload users, tags and comments
    changesets = changesets.preload(:user, :changeset_tags, :comments)

    # create the results document
    results = OSM::API.new.get_xml_doc

    # add all matching changesets to the XML results document
    changesets.order("created_at DESC").limit(100).each do |cs|
      results.root << cs.to_xml_node
    end

    render :xml => results.to_s
  end

  ##
  # updates a changeset's tags. none of the changeset's attributes are
  # user-modifiable, so they will be ignored.
  #
  # changesets are not (yet?) versioned, so we don't have to deal with
  # history tables here. changesets are locked to a single user, however.
  #
  # after succesful update, returns the XML of the changeset.
  def update
    # request *must* be a PUT.
    assert_method :put

    changeset = Changeset.find(params[:id])
    new_changeset = Changeset.from_xml(request.raw_post)

    check_changeset_consistency(changeset, current_user)
    changeset.update_from(new_changeset, current_user)
    render :xml => changeset.to_xml.to_s
  end

  ##
  # list non-empty changesets in reverse chronological order
  def index
    @params = params.permit(:display_name, :bbox, :friends, :nearby, :max_id, :list)

    if request.format == :atom && @params[:max_id]
      redirect_to url_for(@params.merge(:max_id => nil)), :status => :moved_permanently
      return
    end

    if @params[:display_name]
      user = User.find_by(:display_name => @params[:display_name])
      if !user || !user.active?
        render_unknown_user @params[:display_name]
        return
      end
    end

    if (@params[:friends] || @params[:nearby]) && !current_user
      require_user
      return
    end

    if request.format == :html && !@params[:list]
      require_oauth
      render :action => :history, :layout => map_layout
    else
      changesets = conditions_nonempty(Changeset.all)

      if @params[:display_name]
        changesets = if user.data_public? || user == current_user
                       changesets.where(:user_id => user.id)
                     else
                       changesets.where("false")
                     end
      elsif @params[:bbox]
        changesets = conditions_bbox(changesets, BoundingBox.from_bbox_params(params))
      elsif @params[:friends] && current_user
        changesets = changesets.where(:user_id => current_user.friend_users.identifiable)
      elsif @params[:nearby] && current_user
        changesets = changesets.where(:user_id => current_user.nearby)
      end

      changesets = changesets.where("changesets.id <= ?", @params[:max_id]) if @params[:max_id]

      @edits = changesets.order("changesets.id DESC").limit(20).preload(:user, :changeset_tags, :comments)

      render :action => :index, :layout => false
    end
  end

  ##
  # list edits as an atom feed
  def feed
    index
  end

  ##
  # Adds a subscriber to the changeset
  def subscribe
    # Check the arguments are sane
    raise OSM::APIBadUserInput, "No id was given" unless params[:id]

    # Extract the arguments
    id = params[:id].to_i

    # Find the changeset and check it is valid
    changeset = Changeset.find(id)
    raise OSM::APIChangesetAlreadySubscribedError, changeset if changeset.subscribers.exists?(current_user.id)

    # Add the subscriber
    changeset.subscribers << current_user

    # Return a copy of the updated changeset
    render :xml => changeset.to_xml.to_s
  end

  ##
  # Removes a subscriber from the changeset
  def unsubscribe
    # Check the arguments are sane
    raise OSM::APIBadUserInput, "No id was given" unless params[:id]

    # Extract the arguments
    id = params[:id].to_i

    # Find the changeset and check it is valid
    changeset = Changeset.find(id)
    raise OSM::APIChangesetNotSubscribedError, changeset unless changeset.subscribers.exists?(current_user.id)

    # Remove the subscriber
    changeset.subscribers.delete(current_user)

    # Return a copy of the updated changeset
    render :xml => changeset.to_xml.to_s
  end

  private

  #------------------------------------------------------------
  # utility functions below.
  #------------------------------------------------------------

  ##
  # if a bounding box was specified do some sanity checks.
  # restrict changesets to those enclosed by a bounding box
  # we need to return both the changesets and the bounding box
  def conditions_bbox(changesets, bbox)
    if bbox
      bbox.check_boundaries
      bbox = bbox.to_scaled

      changesets.where("min_lon < ? and max_lon > ? and min_lat < ? and max_lat > ?",
                       bbox.max_lon.to_i, bbox.min_lon.to_i,
                       bbox.max_lat.to_i, bbox.min_lat.to_i)
    else
      changesets
    end
  end

  ##
  # restrict changesets to those by a particular user
  def conditions_user(changesets, user, name)
    if user.nil? && name.nil?
      changesets
    else
      # shouldn't provide both name and UID
      raise OSM::APIBadUserInput, "provide either the user ID or display name, but not both" if user && name

      # use either the name or the UID to find the user which we're selecting on.
      u = if name.nil?
            # user input checking, we don't have any UIDs < 1
            raise OSM::APIBadUserInput, "invalid user ID" if user.to_i < 1

            u = User.find(user.to_i)
          else
            u = User.find_by(:display_name => name)
          end

      # make sure we found a user
      raise OSM::APINotFoundError if u.nil?

      # should be able to get changesets of public users only, or
      # our own changesets regardless of public-ness.
      unless u.data_public?
        # get optional user auth stuff so that users can see their own
        # changesets if they're non-public
        setup_user_auth

        raise OSM::APINotFoundError if current_user.nil? || current_user != u
      end

      changesets.where(:user_id => u.id)
    end
  end

  ##
  # restrict changes to those closed during a particular time period
  def conditions_time(changesets, time)
    if time.nil?
      changesets
    elsif time.count(",") == 1
      # if there is a range, i.e: comma separated, then the first is
      # low, second is high - same as with bounding boxes.

      # check that we actually have 2 elements in the array
      times = time.split(/,/)
      raise OSM::APIBadUserInput, "bad time range" if times.size != 2

      from, to = times.collect { |t| Time.parse(t) }
      changesets.where("closed_at >= ? and created_at <= ?", from, to)
    else
      # if there is no comma, assume its a lower limit on time
      changesets.where("closed_at >= ?", Time.parse(time))
    end
    # stupid Time seems to throw both of these for bad parsing, so
    # we have to catch both and ensure the correct code path is taken.
  rescue ArgumentError => ex
    raise OSM::APIBadUserInput, ex.message.to_s
  rescue RuntimeError => ex
    raise OSM::APIBadUserInput, ex.message.to_s
  end

  ##
  # return changesets which are open (haven't been closed yet)
  # we do this by seeing if the 'closed at' time is in the future. Also if we've
  # hit the maximum number of changes then it counts as no longer open.
  # if parameter 'open' is nill then open and closed changesets are returned
  def conditions_open(changesets, open)
    if open.nil?
      changesets
    else
      changesets.where("closed_at >= ? and num_changes <= ?",
                       Time.now.getutc, Changeset::MAX_ELEMENTS)
    end
  end

  ##
  # query changesets which are closed
  # ('closed at' time has passed or changes limit is hit)
  def conditions_closed(changesets, closed)
    if closed.nil?
      changesets
    else
      changesets.where("closed_at < ? or num_changes > ?",
                       Time.now.getutc, Changeset::MAX_ELEMENTS)
    end
  end

  ##
  # query changesets by a list of ids
  # (either specified as array or comma-separated string)
  def conditions_ids(changesets, ids)
    if ids.nil?
      changesets
    elsif ids.empty?
      raise OSM::APIBadUserInput, "No changesets were given to search for"
    else
      ids = ids.split(",").collect(&:to_i)
      changesets.where(:id => ids)
    end
  end

  ##
  # eliminate empty changesets (where the bbox has not been set)
  # this should be applied to all changeset list displays
  def conditions_nonempty(changesets)
    changesets.where("num_changes > 0")
  end
end
