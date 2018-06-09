# The ChangesetController is the RESTful interface to Changeset objects

class Api::ChangesetController < ApplicationController
  layout "site"
  require "xml/libxml"

  skip_before_action :verify_authenticity_token
  before_action :authorize, :only => [:create, :update, :upload, :close, :comment, :subscribe, :unsubscribe, :hide_comment, :unhide_comment]
  before_action :require_moderator, :only => [:hide_comment, :unhide_comment]
  before_action :require_allow_write_api, :only => [:create, :update, :upload, :close, :comment, :subscribe, :unsubscribe, :hide_comment, :unhide_comment]
  before_action :require_public_data, :only => [:create, :update, :upload, :close, :comment, :subscribe, :unsubscribe]
  before_action :check_api_writable, :only => [:create, :update, :upload, :comment, :subscribe, :unsubscribe, :hide_comment, :unhide_comment]
  before_action :check_api_readable, :except => [:create, :update, :upload, :download, :index, :list, :feed, :comment, :subscribe, :unsubscribe, :comments_feed]
  around_action :api_call_handle_error, :except => [:list, :feed, :comments_feed]
  around_action :api_call_timeout, :except => [:list, :feed, :comments_feed, :upload]

  # Helper methods for checking consistency
  include ConsistencyValidations
  include Changesetable

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
  def show
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
  # index changesets by bounding box, time, user or open/closed status.
  def index
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

  ##
  # Sets visible flag on comment to false
  def hide_comment
    # Check the arguments are sane
    raise OSM::APIBadUserInput, "No id was given" unless params[:id]

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
    raise OSM::APIBadUserInput, "No id was given" unless params[:id]

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
  # Add a comment to a changeset
  def comment
    # Check the arguments are sane
    raise OSM::APIBadUserInput, "No id was given" unless params[:id]
    raise OSM::APIBadUserInput, "No text was given" if params[:text].blank?

    # Extract the arguments
    id = params[:id].to_i
    body = params[:text]

    # Find the changeset and check it is valid
    changeset = Changeset.find(id)
    raise OSM::APIChangesetNotYetClosedError, changeset if changeset.is_open?

    # Add a comment to the changeset
    comment = changeset.comments.create(:changeset => changeset,
                                        :body => body,
                                        :author => current_user)

    # Notify current subscribers of the new comment
    changeset.subscribers.visible.each do |user|
      Notifier.changeset_comment_notification(comment, user).deliver_now if current_user != user
    end

    # Add the commenter to the subscribers if necessary
    changeset.subscribers << current_user unless changeset.subscribers.exists?(current_user.id)

    # Return a copy of the updated changeset
    render :xml => changeset.to_xml.to_s
  end
end
