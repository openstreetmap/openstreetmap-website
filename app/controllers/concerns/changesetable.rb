module Changesetable
  extend ActiveSupport::Concern

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

  ##
  # Get the maximum number of comments to return
  def comments_limit
    if params[:limit]
      if params[:limit].to_i > 0 && params[:limit].to_i <= 10000
        params[:limit].to_i
      else
        raise OSM::APIBadUserInput, "Comments limit must be between 1 and 10000"
      end
    else
      100
    end
  end
end
