# The ChangesetController is the RESTful interface to Changeset objects

class ChangesetController < ApplicationController
  layout "site"
  require "xml/libxml"

  skip_before_action :verify_authenticity_token, :except => [:list]
  before_action :authorize_web, :only => [:list, :feed, :comments_feed]
  before_action :set_locale, :only => [:list, :feed, :comments_feed]
  before_action :authorize, :only => [:create, :update, :delete, :upload, :include, :close, :comment, :subscribe, :unsubscribe, :hide_comment, :unhide_comment]
  before_action :require_moderator, :only => [:hide_comment, :unhide_comment]
  before_action :require_allow_write_api, :only => [:create, :update, :delete, :upload, :include, :close, :comment, :subscribe, :unsubscribe, :hide_comment, :unhide_comment]
  before_action :require_public_data, :only => [:create, :update, :delete, :upload, :include, :close, :comment, :subscribe, :unsubscribe]
  before_action :check_api_writable, :only => [:create, :update, :delete, :upload, :include, :comment, :subscribe, :unsubscribe, :hide_comment, :unhide_comment]
  before_action :check_api_readable, :except => [:create, :update, :delete, :upload, :download, :query, :list, :feed, :comment, :subscribe, :unsubscribe, :comments_feed]
  before_action(:only => [:list, :feed, :comments_feed]) { |c| c.check_database_readable(true) }
  around_action :api_call_handle_error, :except => [:list, :feed, :comments_feed]
  around_action :api_call_timeout, :except => [:list, :feed, :comments_feed, :upload]
  around_action :web_timeout, :only => [:list, :feed, :comments_feed]

  # Helper methods for checking consistency
  include ConsistencyValidations

  # Create a changeset from XML.
  def create
    assert_method :put

    cs = Changeset.from_xml(request.raw_post, true)

    # Assume that Changeset.from_xml has thrown an exception if there is an error parsing the xml
    cs.user_id = @user.id
    cs.save_with_tags!

    # Subscribe user to changeset comments
    cs.subscribers << @user

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
    check_changeset_consistency(changeset, @user)

    # to close the changeset, we'll just set its closed_at time to
    # now. this might not be enough if there are concurrency issues,
    # but we'll have to wait and see.
    changeset.set_closed_time_now

    changeset.save!
    render :nothing => true
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
    check_changeset_consistency(cs, @user)

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
    check_changeset_consistency(changeset, @user)

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

    check_changeset_consistency(changeset, @user)
    changeset.update_from(new_changeset, @user)
    render :xml => changeset.to_xml
  end

  ##
  # list non-empty changesets in reverse chronological order
  def list
    if request.format == :atom && params[:max_id]
      redirect_to url_for(params.merge(:max_id => nil)), :status => :moved_permanently
      return
    end

    if params[:display_name]
      user = User.find_by(:display_name => params[:display_name])
      if !user || !user.active?
        render_unknown_user params[:display_name]
        return
      end
    end

    if (params[:friends] || params[:nearby]) && !@user
      require_user
      return
    end

    if request.format == :html && !params[:list]
      require_oauth
      render :action => :history, :layout => map_layout
    else
      changesets = conditions_nonempty(Changeset.all)

      if params[:display_name]
        changesets = if user.data_public? || user == @user
                       changesets.where(:user_id => user.id)
                     else
                       changesets.where("false")
                     end
      elsif params[:bbox]
        changesets = conditions_bbox(changesets, BoundingBox.from_bbox_params(params))
      elsif params[:friends] && @user
        changesets = changesets.where(:user_id => @user.friend_users.identifiable)
      elsif params[:nearby] && @user
        changesets = changesets.where(:user_id => @user.nearby)
      end

      if params[:max_id]
        changesets = changesets.where("changesets.id <= ?", params[:max_id])
      end

      @edits = changesets.order("changesets.id DESC").limit(20).preload(:user, :changeset_tags, :comments)

      render :action => :list, :layout => false
    end
  end

  ##
  # list edits as an atom feed
  def feed
    list
  end

  ##
  # Add a comment to a changeset
  def comment
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]
    raise OSM::APIBadUserInput.new("No text was given") if params[:text].blank?

    # Extract the arguments
    id = params[:id].to_i
    body = params[:text]

    # Find the changeset and check it is valid
    changeset = Changeset.find(id)
    raise OSM::APIChangesetNotYetClosedError.new(changeset) if changeset.is_open?

    # Add a comment to the changeset
    comment = changeset.comments.create(:changeset => changeset,
                                        :body => body,
                                        :author => @user)

    # Notify current subscribers of the new comment
    changeset.subscribers.visible.each do |user|
      if @user != user
        Notifier.changeset_comment_notification(comment, user).deliver_now
      end
    end

    # Add the commenter to the subscribers if necessary
    changeset.subscribers << @user unless changeset.subscribers.exists?(@user.id)

    # Return a copy of the updated changeset
    render :xml => changeset.to_xml.to_s
  end

  ##
  # Adds a subscriber to the changeset
  def subscribe
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Extract the arguments
    id = params[:id].to_i

    # Find the changeset and check it is valid
    changeset = Changeset.find(id)
    raise OSM::APIChangesetNotYetClosedError.new(changeset) if changeset.is_open?
    raise OSM::APIChangesetAlreadySubscribedError.new(changeset) if changeset.subscribers.exists?(@user.id)

    # Add the subscriber
    changeset.subscribers << @user

    # Return a copy of the updated changeset
    render :xml => changeset.to_xml.to_s
  end

  ##
  # Removes a subscriber from the changeset
  def unsubscribe
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Extract the arguments
    id = params[:id].to_i

    # Find the changeset and check it is valid
    changeset = Changeset.find(id)
    raise OSM::APIChangesetNotYetClosedError.new(changeset) if changeset.is_open?
    raise OSM::APIChangesetNotSubscribedError.new(changeset) unless changeset.subscribers.exists?(@user.id)

    # Remove the subscriber
    changeset.subscribers.delete(@user)

    # Return a copy of the updated changeset
    render :xml => changeset.to_xml.to_s
  end

  ##
  # Sets visible flag on comment to false
  def hide_comment
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Extract the arguments
    id = params[:id].to_i

    # Find the changeset
    comment = ChangesetComment.find(id)

    # Hide the comment
    comment.update(:visible => false)

    # Return a copy of the updated changeset
    render :xml => comment.changeset.to_xml.to_s
  end

  ##
  # Sets visible flag on comment to true
  def unhide_comment
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Extract the arguments
    id = params[:id].to_i

    # Find the changeset
    comment = ChangesetComment.find(id)

    # Unhide the comment
    comment.update(:visible => true)

    # Return a copy of the updated changeset
    render :xml => comment.changeset.to_xml.to_s
  end

  ##
  # Get a feed of recent changeset comments
  def comments_feed
    if params[:id]
      # Extract the arguments
      id = params[:id].to_i

      # Find the changeset
      changeset = Changeset.find(id)

      # Return comments for this changeset only
      @comments = changeset.comments.includes(:author, :changeset).limit(comments_limit)
    else
      # Return comments
      @comments = ChangesetComment.includes(:author, :changeset).where(:visible => :true).order("created_at DESC").limit(comments_limit).preload(:changeset)
    end

    # Render the result
    respond_to do |format|
      format.rss
    end
  rescue OSM::APIBadUserInput
    head :bad_request
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
      raise OSM::APIBadUserInput.new("provide either the user ID or display name, but not both") if user && name

      # use either the name or the UID to find the user which we're selecting on.
      u = if name.nil?
            # user input checking, we don't have any UIDs < 1
            raise OSM::APIBadUserInput.new("invalid user ID") if user.to_i < 1
            u = User.find(user.to_i)
          else
            u = User.find_by(:display_name => name)
          end

      # make sure we found a user
      raise OSM::APINotFoundError.new if u.nil?

      # should be able to get changesets of public users only, or
      # our own changesets regardless of public-ness.
      unless u.data_public?
        # get optional user auth stuff so that users can see their own
        # changesets if they're non-public
        setup_user_auth

        raise OSM::APINotFoundError if @user.nil? || @user.id != u.id
      end

      changesets.where(:user_id => u.id)
    end
  end

  ##
  # restrict changes to those closed during a particular time period
  def conditions_time(changesets, time)
    if time.nil?
      return changesets
    elsif time.count(",") == 1
      # if there is a range, i.e: comma separated, then the first is
      # low, second is high - same as with bounding boxes.

      # check that we actually have 2 elements in the array
      times = time.split(/,/)
      raise OSM::APIBadUserInput.new("bad time range") if times.size != 2

      from, to = times.collect { |t| DateTime.parse(t) }
      return changesets.where("closed_at >= ? and created_at <= ?", from, to)
    else
      # if there is no comma, assume its a lower limit on time
      return changesets.where("closed_at >= ?", DateTime.parse(time))
    end
    # stupid DateTime seems to throw both of these for bad parsing, so
    # we have to catch both and ensure the correct code path is taken.
  rescue ArgumentError => ex
    raise OSM::APIBadUserInput.new(ex.message.to_s)
  rescue RuntimeError => ex
    raise OSM::APIBadUserInput.new(ex.message.to_s)
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
      raise OSM::APIBadUserInput.new("No changesets were given to search for")
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

  ##
  # Get the maximum number of comments to return
  def comments_limit
    if params[:limit]
      if params[:limit].to_i > 0 && params[:limit].to_i <= 10000
        params[:limit].to_i
      else
        raise OSM::APIBadUserInput.new("Comments limit must be between 1 and 10000")
      end
    else
      100
    end
  end
end
