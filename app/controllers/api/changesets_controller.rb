# The ChangesetController is the RESTful interface to Changeset objects

module Api
  class ChangesetsController < ApiController
    include QueryMethods

    before_action :check_api_writable, :only => [:create, :update, :upload]
    before_action :setup_user_auth, :only => [:show]
    before_action :authorize, :only => [:create, :update, :upload, :close]

    authorize_resource

    before_action :require_public_data, :only => [:create, :update, :upload, :close]
    before_action :set_request_formats, :except => [:create, :close, :upload]

    skip_around_action :api_call_timeout, :only => [:upload]

    # Helper methods for checking consistency
    include ConsistencyValidations

    ##
    # query changesets by bounding box, time, user or open/closed status.
    def index
      raise OSM::APIBadUserInput, "cannot use order=oldest with time" if params[:time] && params[:order] == "oldest"

      # find any bounding box
      bbox = BoundingBox.from_bbox_params(params) if params["bbox"]

      # create the conditions that the user asked for. some or all of
      # these may be nil.
      changesets = Changeset.all
      changesets = conditions_bbox(changesets, bbox)
      changesets = conditions_user(changesets, params["user"], params["display_name"])
      changesets = conditions_time(changesets, params["time"])
      changesets = query_conditions_time(changesets)
      changesets = conditions_open(changesets, params["open"])
      changesets = conditions_closed(changesets, params["closed"])
      changesets = conditions_ids(changesets, params["changesets"])

      # sort the changesets
      changesets = if params[:order] == "oldest"
                     changesets.order(:created_at => :asc)
                   else
                     changesets.order(:created_at => :desc)
                   end

      # limit the result
      changesets = query_limit(changesets)

      # preload users, tags and comments, and render result
      @changesets = changesets.preload(:user, :changeset_tags, :comments)

      respond_to do |format|
        format.xml
        format.json
      end
    end

    ##
    # Return XML giving the basic info about the changeset. Does not
    # return anything about the nodes, ways and relations in the changeset.
    def show
      @changeset = Changeset.find(params[:id])
      if params[:include_discussion].presence
        @comments = @changeset.comments
        @comments = @comments.unscope(:where => :visible) if params[:show_hidden_comments].presence && can?(:create, :changeset_comment_visibility)
        @comments = @comments.includes(:author)
      end

      respond_to do |format|
        format.xml
        format.json
      end
    end

    # Create a changeset from XML.
    def create
      cs = Changeset.from_xml(request.raw_post, :create => true)

      # Assume that Changeset.from_xml has thrown an exception if there is an error parsing the xml
      cs.user = current_user
      cs.save_with_tags!

      # Subscribe user to changeset comments
      cs.subscribers << current_user

      render :plain => cs.id.to_s
    end

    ##
    # marks a changeset as closed. this may be called multiple times
    # on the same changeset, so is idempotent.
    def close
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
      changeset = Changeset.find(params[:id])
      check_changeset_consistency(changeset, current_user)

      diff_reader = DiffReader.new(request.raw_post, changeset)
      Changeset.transaction do
        result = diff_reader.commit
        # the number of changes in this changeset has already been
        # updated and is visible in this transaction so we don't need
        # to allow for any more when checking the limit
        check_rate_limit(0)
        render :xml => result.to_s
      end
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
      @changeset = Changeset.find(params[:id])
      new_changeset = Changeset.from_xml(request.raw_post)

      check_changeset_consistency(@changeset, current_user)
      @changeset.update_from(new_changeset, current_user)
      render "show"

      respond_to do |format|
        format.xml
        format.json
      end
    end

    private

    #------------------------------------------------------------
    # utility functions below.
    #------------------------------------------------------------

    ##
    # if a bounding box was specified do some sanity checks.
    # restrict changesets to those enclosed by a bounding box
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

              u = User.find_by(:id => user.to_i)
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

        changesets.where(:user => u)
      end
    end

    ##
    # restrict changesets to those during a particular time period
    def conditions_time(changesets, time)
      if time.nil?
        changesets
      elsif time.count(",") == 1
        # if there is a range, i.e: comma separated, then the first is
        # low, second is high - same as with bounding boxes.

        # check that we actually have 2 elements in the array
        times = time.split(",")
        raise OSM::APIBadUserInput, "bad time range" if times.size != 2

        from, to = times.collect { |t| Time.parse(t).utc }
        changesets.where("closed_at >= ? and created_at <= ?", from, to)
      else
        # if there is no comma, assume its a lower limit on time
        changesets.where(:closed_at => Time.parse(time).utc..)
      end
      # stupid Time seems to throw both of these for bad parsing, so
      # we have to catch both and ensure the correct code path is taken.
    rescue ArgumentError, RuntimeError => e
      raise OSM::APIBadUserInput, e.message.to_s
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
                         Time.now.utc, Changeset::MAX_ELEMENTS)
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
                         Time.now.utc, Changeset::MAX_ELEMENTS)
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
  end
end
