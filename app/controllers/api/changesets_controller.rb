# The ChangesetController is the RESTful interface to Changeset objects

module Api
  class ChangesetsController < ApiController
    before_action :check_api_writable, :only => [:create, :update, :upload, :subscribe, :unsubscribe]
    before_action :setup_user_auth, :only => [:show]
    before_action :authorize, :only => [:create, :update, :upload, :close, :subscribe, :unsubscribe]

    authorize_resource

    before_action :require_public_data, :only => [:create, :update, :upload, :close, :subscribe, :unsubscribe]
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
      changesets = conditions_from_to(changesets, params["from"], params["to"])
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
      changesets = changesets.limit(result_limit)

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
        @comments = @comments.unscope(:where => :visible) if params[:show_hidden_comments].presence && can?(:restore, ChangesetComment)
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
      cs.subscribe(current_user)

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
      elements.sort_by! { |e| [e.timestamp, e.version] }

      # generate an output element for each operation. note: we avoid looking
      # at the history because it is simpler - but it would be more correct to
      # check these assertions.
      @created = []
      @modified = []
      @deleted = []

      elements.each do |elt|
        if elt.version == 1
          # first version, so it must be newly-created.
          @created << elt
        elsif elt.visible
          # must be a modify
          @modified << elt
        else
          # if the element isn't visible then it must have been deleted
          @deleted << elt
        end
      end

      respond_to do |format|
        format.xml
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

    ##
    # Adds a subscriber to the changeset
    def subscribe
      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      # Extract the arguments
      id = params[:id].to_i

      # Find the changeset and check it is valid
      changeset = Changeset.find(id)
      raise OSM::APIChangesetAlreadySubscribedError, changeset if changeset.subscribed?(current_user)

      # Add the subscriber
      changeset.subscribe(current_user)

      # Return a copy of the updated changeset
      @changeset = changeset
      render "show"

      respond_to do |format|
        format.xml
        format.json
      end
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
      raise OSM::APIChangesetNotSubscribedError, changeset unless changeset.subscribed?(current_user)

      # Remove the subscriber
      changeset.unsubscribe(current_user)

      # Return a copy of the updated changeset
      @changeset = changeset
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
    # restrict changesets to those opened during a particular time period
    # works similar to from..to of notes controller, including the requirement of 'from' when specifying 'to'
    def conditions_from_to(changesets, from, to)
      if from
        begin
          from = Time.parse(from).utc
        rescue ArgumentError
          raise OSM::APIBadUserInput, "Date #{from} is in a wrong format"
        end

        begin
          to = if to
                 Time.parse(to).utc
               else
                 Time.now.utc
               end
        rescue ArgumentError
          raise OSM::APIBadUserInput, "Date #{to} is in a wrong format"
        end

        changesets.where(:created_at => from..to)
      else
        changesets
      end
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

    ##
    # Get the maximum number of results to return
    def result_limit
      if params[:limit]
        if params[:limit].to_i.positive? && params[:limit].to_i <= Settings.max_changeset_query_limit
          params[:limit].to_i
        else
          raise OSM::APIBadUserInput, "Changeset limit must be between 1 and #{Settings.max_changeset_query_limit}"
        end
      else
        Settings.default_changeset_query_limit
      end
    end
  end
end
