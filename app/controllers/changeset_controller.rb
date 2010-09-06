# The ChangesetController is the RESTful interface to Changeset objects

class ChangesetController < ApplicationController
  layout 'site'
  require 'xml/libxml'

  before_filter :authorize_web, :only => [:list]
  before_filter :set_locale, :only => [:list]
  before_filter :authorize, :only => [:create, :update, :delete, :upload, :include, :close]
  before_filter :require_allow_write_api, :only => [:create, :update, :delete, :upload, :include, :close]
  before_filter :require_public_data, :only => [:create, :update, :delete, :upload, :include, :close]
  before_filter :check_api_writable, :only => [:create, :update, :delete, :upload, :include]
  before_filter :check_api_readable, :except => [:create, :update, :delete, :upload, :download, :query, :list]
  before_filter(:only => [:list]) { |c| c.check_database_readable(true) }
  after_filter :compress_output
  around_filter :api_call_handle_error, :except => [:list]
  around_filter :web_timeout, :only => [:list]

  filter_parameter_logging "<osmChange version"

  # Help methods for checking boundary sanity and area size
  include MapBoundary

  # Helper methods for checking consistency
  include ConsistencyValidations

  # Create a changeset from XML.
  def create
    assert_method :put

    cs = Changeset.from_xml(request.raw_post, true)

    # Assume that Changeset.from_xml has thrown an exception if there is an error parsing the xml
    cs.user_id = @user.id
    cs.save_with_tags!
    render :text => cs.id.to_s, :content_type => "text/plain"
  end

  ##
  # Return XML giving the basic info about the changeset. Does not 
  # return anything about the nodes, ways and relations in the changeset.
  def read
    changeset = Changeset.find(params[:id])
    render :text => changeset.to_xml.to_s, :content_type => "text/xml"
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
    lon = Array.new
    lat = Array.new
    
    # the request is in pseudo-osm format... this is kind-of an
    # abuse, maybe should change to some other format?
    doc = XML::Parser.string(request.raw_post).parse
    doc.find("//osm/node").each do |n|
      lon << n['lon'].to_f * GeoRecord::SCALE
      lat << n['lat'].to_f * GeoRecord::SCALE
    end
    
    # add the existing bounding box to the lon-lat array
    lon << cs.min_lon unless cs.min_lon.nil?
    lat << cs.min_lat unless cs.min_lat.nil?
    lon << cs.max_lon unless cs.max_lon.nil?
    lat << cs.max_lat unless cs.max_lat.nil?
    
    # collapse the arrays to minimum and maximum
    cs.min_lon, cs.min_lat, cs.max_lon, cs.max_lat = 
      lon.min, lat.min, lon.max, lat.max
    
    # save the larger bounding box and return the changeset, which
    # will include the bigger bounding box.
    cs.save!
    render :text => cs.to_xml.to_s, :content_type => "text/xml"
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
      render :text => result.to_s, :content_type => "text/xml"
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
    
    # get all the elements in the changeset and stick them in a big array.
    elements = [changeset.old_nodes, 
                changeset.old_ways, 
                changeset.old_relations].flatten
    
    # sort the elements by timestamp and version number, as this is the 
    # almost sensible ordering available. this would be much nicer if 
    # global (SVN-style) versioning were used - then that would be 
    # unambiguous.
    elements.sort! do |a, b| 
      if (a.timestamp == b.timestamp)
        a.version <=> b.version
      else
        a.timestamp <=> b.timestamp 
      end
    end
    
    # create an osmChange document for the output
    result = OSM::API.new.get_xml_doc
    result.root.name = "osmChange"

    # generate an output element for each operation. note: we avoid looking
    # at the history because it is simpler - but it would be more correct to 
    # check these assertions.
    elements.each do |elt|
      result.root <<
        if (elt.version == 1) 
          # first version, so it must be newly-created.
          created = XML::Node.new "create"
          created << elt.to_xml_node
        else
          # get the previous version from the element history
          prev_elt = elt.class.find(:first, :conditions => 
                                    ['id = ? and version = ?',
                                     elt.id, elt.version])
          unless elt.visible
            # if the element isn't visible then it must have been deleted, so
            # output the *previous* XML
            deleted = XML::Node.new "delete"
            deleted << prev_elt.to_xml_node
          else
            # must be a modify, for which we don't need the previous version
            # yet...
            modified = XML::Node.new "modify"
            modified << elt.to_xml_node
          end
        end
    end

    render :text => result.to_s, :content_type => "text/xml"
  end

  ##
  # query changesets by bounding box, time, user or open/closed status.
  def query
    # create the conditions that the user asked for. some or all of
    # these may be nil.
    conditions = conditions_bbox(params['bbox'])
    conditions = cond_merge conditions, conditions_user(params['user'], params['display_name'])
    conditions = cond_merge conditions, conditions_time(params['time'])
    conditions = cond_merge conditions, conditions_open(params['open'])
    conditions = cond_merge conditions, conditions_closed(params['closed'])

    # create the results document
    results = OSM::API.new.get_xml_doc

    # add all matching changesets to the XML results document
    Changeset.find(:all, 
                   :conditions => conditions, 
                   :limit => 100,
                   :order => 'created_at desc').each do |cs|
      results.root << cs.to_xml_node
    end

    render :text => results.to_s, :content_type => "text/xml"
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

    unless new_changeset.nil?
      check_changeset_consistency(changeset, @user)
      changeset.update_from(new_changeset, @user)
      render :text => changeset.to_xml, :mime_type => "text/xml"
    else
      
      render :nothing => true, :status => :bad_request
    end
  end

  
  
  ##
  # list edits (open changesets) in reverse chronological order
  def list
    if request.format == :atom and params[:page]
      redirect_to params.merge({ :page => nil }), :status => :moved_permanently
    else
      conditions = conditions_nonempty

      if params[:display_name]
        user = User.find_by_display_name(params[:display_name], :conditions => { :status => ["active", "confirmed"] })
        
        if user 
          if user.data_public? or user == @user
            conditions = cond_merge conditions, ['user_id = ?', user.id]
          else
            conditions = cond_merge conditions, ['false']
          end
        elsif request.format == :html
          @title = t 'user.no_such_user.title'
          @not_found_user = params[:display_name]
          render :template => 'user/no_such_user', :status => :not_found
        end
      end
      
      if params[:bbox]
        bbox = params[:bbox]
      elsif params[:minlon] and params[:minlat] and params[:maxlon] and params[:maxlat]
        bbox = params[:minlon] + ',' + params[:minlat] + ',' + params[:maxlon] + ',' + params[:maxlat]
      end
      
      if bbox
        conditions = cond_merge conditions, conditions_bbox(bbox)
        bbox = BoundingBox.from_s(bbox)
        bbox_link = render_to_string :partial => "bbox", :object => bbox
      end
      
      if user
        user_link = render_to_string :partial => "user", :object => user
      end
      
      if user and bbox
        @title =  t 'changeset.list.title_user_bbox', :user => user.display_name, :bbox => bbox.to_s
        @heading =  t 'changeset.list.heading_user_bbox', :user => user.display_name, :bbox => bbox.to_s
        @description = t 'changeset.list.description_user_bbox', :user => user_link, :bbox => bbox_link
      elsif user
        @title =  t 'changeset.list.title_user', :user => user.display_name
        @heading =  t 'changeset.list.heading_user', :user => user.display_name
        @description = t 'changeset.list.description_user', :user => user_link
      elsif bbox
        @title =  t 'changeset.list.title_bbox', :bbox => bbox.to_s
        @heading =  t 'changeset.list.heading_bbox', :bbox => bbox.to_s
        @description = t 'changeset.list.description_bbox', :bbox => bbox_link
      else
        @title =  t 'changeset.list.title'
        @heading =  t 'changeset.list.heading'
        @description = t 'changeset.list.description'
      end

      @page = (params[:page] || 1).to_i
      @page_size = 20

      @edits = Changeset.find(:all,
                              :include => [:user, :changeset_tags],
                              :conditions => conditions,
                              :order => "changesets.created_at DESC",
                              :offset => (@page - 1) * @page_size,
                              :limit => @page_size)
    end
  end

private
  #------------------------------------------------------------
  # utility functions below.
  #------------------------------------------------------------  

  ##
  # merge two conditions
  def cond_merge(a, b)
    if a and b
      a_str = a.shift
      b_str = b.shift
      return [ a_str + " AND " + b_str ] + a + b
    elsif a 
      return a
    else b
      return b
    end
  end

  ##
  # if a bounding box was specified then parse it and do some sanity 
  # checks. this is mostly the same as the map call, but without the 
  # area restriction.
  def conditions_bbox(bbox)
    unless bbox.nil?
      raise OSM::APIBadUserInput.new("Bounding box should be min_lon,min_lat,max_lon,max_lat") unless bbox.count(',') == 3
      bbox = sanitise_boundaries(bbox.split(/,/))
      raise OSM::APIBadUserInput.new("Minimum longitude should be less than maximum.") unless bbox[0] <= bbox[2]
      raise OSM::APIBadUserInput.new("Minimum latitude should be less than maximum.") unless bbox[1] <= bbox[3]
      return ['min_lon < ? and max_lon > ? and min_lat < ? and max_lat > ?',
              (bbox[2] * GeoRecord::SCALE).to_i,
              (bbox[0] * GeoRecord::SCALE).to_i,
              (bbox[3] * GeoRecord::SCALE).to_i,
              (bbox[1] * GeoRecord::SCALE).to_i]
    else
      return nil
    end
  end

  ##
  # restrict changesets to those by a particular user
  def conditions_user(user, name)
    unless user.nil? and name.nil?
      # shouldn't provide both name and UID
      raise OSM::APIBadUserInput.new("provide either the user ID or display name, but not both") if user and name

      # use either the name or the UID to find the user which we're selecting on.
      u = if name.nil?
            # user input checking, we don't have any UIDs < 1
            raise OSM::APIBadUserInput.new("invalid user ID") if user.to_i < 1
            u = User.find(user.to_i)
          else
            u = User.find_by_display_name(name)
          end

      # make sure we found a user
      raise OSM::APINotFoundError.new if u.nil?

      # should be able to get changesets of public users only, or 
      # our own changesets regardless of public-ness.
      unless u.data_public?
        # get optional user auth stuff so that users can see their own
        # changesets if they're non-public
        setup_user_auth
        
        raise OSM::APINotFoundError if @user.nil? or @user.id != u.id
      end
      return ['user_id = ?', u.id]
    else
      return nil
    end
  end

  ##
  # restrict changes to those closed during a particular time period
  def conditions_time(time) 
    unless time.nil?
      # if there is a range, i.e: comma separated, then the first is 
      # low, second is high - same as with bounding boxes.
      if time.count(',') == 1
        # check that we actually have 2 elements in the array
        times = time.split(/,/)
        raise OSM::APIBadUserInput.new("bad time range") if times.size != 2 

        from, to = times.collect { |t| DateTime.parse(t) }
        return ['closed_at >= ? and created_at <= ?', from, to]
      else
        # if there is no comma, assume its a lower limit on time
        return ['closed_at >= ?', DateTime.parse(time)]
      end
    else
      return nil
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
  # if parameter 'open' is nill then open and closed changsets are returned
  def conditions_open(open)
    return open.nil? ? nil : ['closed_at >= ? and num_changes <= ?', 
                              Time.now.getutc, Changeset::MAX_ELEMENTS]
  end
  
  ##
  # query changesets which are closed
  # ('closed at' time has passed or changes limit is hit)
  def conditions_closed(closed)
    return closed.nil? ? nil : ['closed_at < ? or num_changes > ?', 
                                Time.now.getutc, Changeset::MAX_ELEMENTS]
  end

  ##
  # eliminate empty changesets (where the bbox has not been set)
  # this should be applied to all changeset list displays
  def conditions_nonempty()
    return ['min_lat IS NOT NULL']
  end
  
end
