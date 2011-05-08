class MapBugsController < ApplicationController

  layout 'site', :only => [:my_bugs]

  before_filter :check_api_readable
  before_filter :authorize_web, :only => [:add_bug, :close_bug, :edit_bug, :delete, :my_bugs]
  before_filter :check_api_writable, :only => [:add_bug, :close_bug, :edit_bug, :delete]
  before_filter :require_moderator, :only => [:delete]
  before_filter :set_locale, :only => [:my_bugs]
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  # Help methods for checking boundary sanity and area size
  include MapBoundary

  def get_bugs

    # Figure out the bbox
    bbox = params['bbox']

    if bbox and bbox.count(',') == 3
      bbox = bbox.split(',')
      @min_lon, @min_lat, @max_lon, @max_lat = sanitise_boundaries(bbox)
    else
      #Fallback to old style, this is deprecated and should not be used
      raise OSM::APIBadUserInput.new("No l was given") unless params['l']
      raise OSM::APIBadUserInput.new("No r was given") unless params['r']
      raise OSM::APIBadUserInput.new("No b was given") unless params['b']
      raise OSM::APIBadUserInput.new("No t was given") unless params['t']

      @min_lon = params['l'].to_f
      @max_lon = params['r'].to_f
      @min_lat = params['b'].to_f
      @max_lat = params['t'].to_f
    end

    limit = getLimit
    conditions = closedCondition
	
    check_boundaries(@min_lon, @min_lat, @max_lon, @max_lat, MAX_BUG_REQUEST_AREA)

    @bugs = MapBug.find_by_area(@min_lat, @min_lon, @max_lat, @max_lon, :include => :comments, :order => "updated_at DESC", :limit => limit, :conditions => conditions)

    respond_to do |format|
      format.html {render :template => 'map_bugs/get_bugs.js', :content_type => "text/javascript"}
      format.rss {render :template => 'map_bugs/get_bugs.rss'}
      format.js
      format.xml {render :template => 'map_bugs/get_bugs.xml'}
      format.json { render :json => @bugs.to_json(:methods => [:lat, :lon], :only => [:id, :status, :created_at], :include => { :comments => { :only => [:author_name, :created_at, :body]}}) }	  
      format.gpx {render :template => 'map_bugs/get_bugs.gpx'}
    end
  end

  def add_bug
    raise OSM::APIBadUserInput.new("No lat was given") unless params['lat']
    raise OSM::APIBadUserInput.new("No lon was given") unless params['lon']
    raise OSM::APIBadUserInput.new("No text was given") unless params['text']

    lon = params['lon'].to_f
    lat = params['lat'].to_f
    comment = params['text']

    name = "NoName"
    name = params['name'] if params['name']

    #Include in a transaction to ensure that there is always a map_bug_comment for every map_bug
    MapBug.transaction do
      @bug = MapBug.create_bug(lat, lon)

      #TODO: move this into a helper function
      begin
        url = "http://nominatim.openstreetmap.org/reverse?lat=" + lat.to_s + "&lon=" + lon.to_s + "&zoom=16" 
        response = REXML::Document.new(Net::HTTP.get(URI.parse(url))) 
		
        if result = response.get_text("reversegeocode/result") 
          @bug.nearby_place = result.to_s 
        else 
          @bug.nearby_place = "unknown"
        end
      rescue Exception => err
        @bug.nearby_place = "unknown"
      end

      @bug.save

      add_comment(@bug, comment, name, "opened")
    end
 
    render_ok
  end

  def edit_bug
    raise OSM::APIBadUserInput.new("No id was given") unless params['id']
    raise OSM::APIBadUserInput.new("No text was given") unless params['text']

    name = "NoName"
    name = params['name'] if params['name']
	
    id = params['id'].to_i

    bug = MapBug.find_by_id(id)
    raise OSM::APINotFoundError unless bug
    raise OSM::APIAlreadyDeletedError unless bug.visible

    MapBug.transaction do
      bug_comment = add_comment(bug, params['text'], name, "commented")
    end

    render_ok
  end

  def close_bug
    raise OSM::APIBadUserInput.new("No id was given") unless params['id']
	
    id = params['id'].to_i
    name = "NoName"
    name = params['name'] if params['name']

    bug = MapBug.find_by_id(id)
    raise OSM::APINotFoundError unless bug
    raise OSM::APIAlreadyDeletedError unless bug.visible

    MapBug.transaction do
      bug.close_bug
      add_comment(bug, :nil, name, "closed")
    end

    render_ok
  end 

  def rss
    limit = getLimit
    conditions = closedCondition

    # Figure out the bbox
    bbox = params['bbox']

    if bbox and bbox.count(',') == 3
      bbox = bbox.split(',')
      @min_lon, @min_lat, @max_lon, @max_lat = sanitise_boundaries(bbox)

      check_boundaries(@min_lon, @min_lat, @max_lon, @max_lat, MAX_BUG_REQUEST_AREA)

      conditions = cond_merge conditions, [OSM.sql_for_area(@min_lat, @min_lon, @max_lat, @max_lon)]
    end

    @comments = MapBugComment.find(:all, :limit => limit, :order => "created_at DESC", :joins => :map_bug, :include => :map_bug, :conditions => conditions)
    render :template => 'map_bugs/rss.rss'
  end

  def read
    @bug = MapBug.find(params['id'])
    raise OSM::APINotFoundError unless @bug
    raise OSM::APIAlreadyDeletedError unless @bug.visible
    
    respond_to do |format|
      format.rss
      format.xml
      format.json { render :json => @bug.to_json(:methods => [:lat, :lon], :only => [:id, :status, :created_at], :include => { :comments => { :only => [:author_name, :created_at, :body]}}) }	  
      format.gpx
    end
  end

  def delete
    bug = MapBug.find(params['id'])
    raise OSM::APINotFoundError unless @bug
    raise OSM::APIAlreadyDeletedError unless @bug.visible

    MapBug.transaction do
      bug.status = "hidden"
      bug.save
      add_comment(bug,:nil,name,"hidden")
    end

    render :text => "ok\n", :content_type => "text/html" 
  end

  def search
    raise OSM::APIBadUserInput.new("No query string was given") unless params['q']
    limit = getLimit
    conditions = closedCondition
    conditions = cond_merge conditions, ['map_bug_comment.body ~ ?', params['q']]
	
    #TODO: There should be a better way to do this.   CloseConditions are ignored at the moment

    bugs2 = MapBug.find(:all, :limit => limit, :order => "updated_at DESC", :joins => :comments, :include => :comments,
                        :conditions => conditions)
    @bugs = bugs2.uniq
    respond_to do |format|
      format.html {render :template => 'map_bugs/get_bugs.js', :content_type => "text/javascript"}
      format.rss {render :template => 'map_bugs/get_bugs.rss'}
      format.js
      format.xml {render :template => 'map_bugs/get_bugs.xml'}
      format.json { render :json => @bugs.to_json(:methods => [:lat, :lon], :only => [:id, :status, :created_at], :include => { :comments => { :only => [:author_name, :created_at, :body]}}) }
      format.gpx {render :template => 'map_bugs/get_bugs.gpx'}
    end
  end

  def my_bugs
    if params[:display_name] 
      @user2 = User.find_by_display_name(params[:display_name], :conditions => { :status => ["active", "confirmed"] }) 
 
      if @user2  
        if @user2.data_public? or @user2 == @user 
          conditions = ['map_bug_comment.author_id = ?', @user2.id] 
        else 
          conditions = ['false'] 
        end 
      else #if request.format == :html 
        @title = t 'user.no_such_user.title' 
        @not_found_user = params[:display_name] 
        render :template => 'user/no_such_user', :status => :not_found 
        return
      end 
    end

    if @user2 
      user_link = render_to_string :partial => "user", :object => @user2 
    end 
    
    @title =  t 'bugs.user.title_user', :user => @user2.display_name 
    @heading =  t 'bugs.user.heading_user', :user => @user2.display_name 
    @description = t 'bugs.user.description_user', :user => user_link
    
    @page = (params[:page] || 1).to_i 
    @page_size = 10

    @bugs = MapBug.find(:all, 
                        :include => [:comments, {:comments => :author}],
                        :joins => :comments,
                        :order => "updated_at DESC",
                        :conditions => conditions,
                        :offset => (@page - 1) * @page_size, 
                        :limit => @page_size).uniq
  end

private 
  #------------------------------------------------------------ 
  # utility functions below. 
  #------------------------------------------------------------   
 
  ## 
  # merge two conditions 
  # TODO: this is a copy from changeset_controler.rb and should be factored out to share
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

  def render_ok
    output_js = :false
    output_js = :true if params['format'] == "js"

    if output_js == :true
      render :text => "osbResponse();", :content_type => "text/javascript" 
    else
      render :text => "ok " + @bug.id.to_s + "\n", :content_type => "text/html" if @bug
      render :text => "ok\n", :content_type => "text/html" unless @bug
    end
  end

  def getLimit
    limit = 100
    limit = params['limit'] if ((params['limit']) && (params['limit'].to_i < 10000) && (params['limit'].to_i > 0))
    return limit
  end

  def closedCondition
    closed_since = 7 unless params['closed']
    closed_since = params['closed'].to_i if params['closed']
	
    if closed_since < 0
      conditions = ["status != 'hidden'"]
    elsif closed_since > 0
      conditions = ["((status = 'open') OR ((status = 'closed' ) AND (closed_at > '" + (Time.now - closed_since.days).to_s + "')))"]
    else
      conditions = ["status = 'open'"]
    end

    return conditions
  end

  def add_comment(bug, comment, name,event) 
    bug_comment = bug.comments.create(:visible => true, :event => event)
    bug_comment.body = comment unless comment == :nil
    if @user  
      bug_comment.author_id = @user.id
      bug_comment.author_name = @user.display_name
    else  
      bug_comment.author_ip = request.remote_ip
      bug_comment.author_name = name + " (a)"
    end
    bug_comment.save 
    bug.save

    sent_to = Set.new
    bug.comments.each do | cmt |
      if cmt.author
        unless sent_to.include?(cmt.author)
          Notifier.deliver_bug_comment_notification(bug_comment, cmt.author) unless cmt.author == @user
          sent_to.add(cmt.author)
        end
      end
    end
  end
end
