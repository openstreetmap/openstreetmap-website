class NoteController < ApplicationController

  layout 'site', :only => [:mine]

  before_filter :check_api_readable
  before_filter :authorize_web, :only => [:create, :close, :update, :delete, :mine]
  before_filter :check_api_writable, :only => [:create, :close, :update, :delete]
  before_filter :require_moderator, :only => [:delete]
  before_filter :set_locale, :only => [:mine]
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  # Help methods for checking boundary sanity and area size
  include MapBoundary

  def list
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
	
    check_boundaries(@min_lon, @min_lat, @max_lon, @max_lat, MAX_NOTE_REQUEST_AREA)

    @notes = Note.find_by_area(@min_lat, @min_lon, @max_lat, @max_lon, :include => :comments, :order => "updated_at DESC", :limit => limit, :conditions => conditions)

    respond_to do |format|
      format.html {render :template => 'note/list.rjs', :content_type => "text/javascript"}
      format.rss {render :template => 'note/list.rss'}
      format.js
      format.xml {render :template => 'note/list.xml'}
      format.json { render :json => @notes.to_json(:methods => [:lat, :lon], :only => [:id, :status, :created_at], :include => { :comments => { :only => [:author_name, :created_at, :body]}}) }	  
      format.gpx {render :template => 'note/list.gpx'}
    end
  end

  def create
    raise OSM::APIBadUserInput.new("No lat was given") unless params['lat']
    raise OSM::APIBadUserInput.new("No lon was given") unless params['lon']
    raise OSM::APIBadUserInput.new("No text was given") unless params['text']

    lon = params['lon'].to_f
    lat = params['lat'].to_f
    comment = params['text']

    name = "NoName"
    name = params['name'] if params['name']

    #Include in a transaction to ensure that there is always a note_comment for every note
    Note.transaction do
      @note = Note.create_bug(lat, lon)

      #TODO: move this into a helper function
      begin
        url = "http://nominatim.openstreetmap.org/reverse?lat=" + lat.to_s + "&lon=" + lon.to_s + "&zoom=16" 
        response = REXML::Document.new(Net::HTTP.get(URI.parse(url))) 
		
        if result = response.get_text("reversegeocode/result") 
          @note.nearby_place = result.to_s 
        else 
          @note.nearby_place = "unknown"
        end
      rescue Exception => err
        @note.nearby_place = "unknown"
      end

      @note.save

      add_comment(@note, comment, name, "opened")
    end
 
    render_ok
  end

  def update
    raise OSM::APIBadUserInput.new("No id was given") unless params['id']
    raise OSM::APIBadUserInput.new("No text was given") unless params['text']

    name = "NoName"
    name = params['name'] if params['name']
	
    id = params['id'].to_i

    note = Note.find(id)
    raise OSM::APINotFoundError unless note
    raise OSM::APIAlreadyDeletedError unless note.visible

    Note.transaction do
      add_comment(note, params['text'], name, "commented")
    end

    render_ok
  end

  def close
    raise OSM::APIBadUserInput.new("No id was given") unless params['id']
	
    id = params['id'].to_i
    name = "NoName"
    name = params['name'] if params['name']

    note = Note.find_by_id(id)
    raise OSM::APINotFoundError unless note
    raise OSM::APIAlreadyDeletedError unless note.visible

    Note.transaction do
      note.close
      add_comment(note, :nil, name, "closed")
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

      check_boundaries(@min_lon, @min_lat, @max_lon, @max_lat, MAX_NOTE_REQUEST_AREA)

      conditions = cond_merge conditions, [OSM.sql_for_area(@min_lat, @min_lon, @max_lat, @max_lon)]
    end

    @comments = NoteComment.find(:all, :limit => limit, :order => "created_at DESC", :joins => :note, :include => :note, :conditions => conditions)
    render :template => 'note/rss.rss'
  end

  def read
    @note = Note.find(params['id'])
    raise OSM::APINotFoundError unless @note
    raise OSM::APIAlreadyDeletedError unless @note.visible
    
    respond_to do |format|
      format.rss
      format.xml
      format.json { render :json => @note.to_json(:methods => [:lat, :lon], :only => [:id, :status, :created_at], :include => { :comments => { :only => [:author_name, :created_at, :body]}}) }	  
      format.gpx
    end
  end

  def delete
    note = note.find(params['id'])
    raise OSM::APINotFoundError unless note
    raise OSM::APIAlreadyDeletedError unless note.visible

    Note.transaction do
      note.status = "hidden"
      note.save
      add_comment(note, :nil, name, "hidden")
    end

    render :text => "ok\n", :content_type => "text/html" 
  end

  def search
    raise OSM::APIBadUserInput.new("No query string was given") unless params['q']
    limit = getLimit
    conditions = closedCondition
    conditions = cond_merge conditions, ['note_comments.body ~ ?', params['q']]
	
    #TODO: There should be a better way to do this.   CloseConditions are ignored at the moment

    @notes = Note.find(:all, :limit => limit, :order => "updated_at DESC", :joins => :comments, :include => :comments, :conditions => conditions).uniq
    respond_to do |format|
      format.html {render :template => 'note/list.rjs', :content_type => "text/javascript"}
      format.rss {render :template => 'note/list.rss'}
      format.js
      format.xml {render :template => 'note/list.xml'}
      format.json { render :json => @notes.to_json(:methods => [:lat, :lon], :only => [:id, :status, :created_at], :include => { :comments => { :only => [:author_name, :created_at, :body]}}) }
      format.gpx {render :template => 'note/list.gpx'}
    end
  end

  def mine
    if params[:display_name] 
      @user2 = User.find_by_display_name(params[:display_name], :conditions => { :status => ["active", "confirmed"] }) 
 
      if @user2  
        if @user2.data_public? or @user2 == @user 
          conditions = ['note_comments.author_id = ?', @user2.id] 
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
    
    @title =  t 'note.mine.title', :user => @user2.display_name 
    @heading =  t 'note.mine.heading', :user => @user2.display_name 
    @description = t 'note.mine.description', :user => user_link
    
    @page = (params[:page] || 1).to_i 
    @page_size = 10

    @notes = Note.find(:all, 
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
      render :text => "ok " + @note.id.to_s + "\n", :content_type => "text/html" if @note
      render :text => "ok\n", :content_type => "text/html" unless @note
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

  def add_comment(note, text, name, event) 
    comment = note.comments.create(:visible => true, :event => event)
    comment.body = text unless text == :nil
    if @user  
      comment.author_id = @user.id
      comment.author_name = @user.display_name
    else  
      comment.author_ip = request.remote_ip
      comment.author_name = name + " (a)"
    end
    comment.save 
    note.save

    sent_to = Set.new
    note.comments.each do | cmt |
      if cmt.author
        unless sent_to.include?(cmt.author)
          Notifier.deliver_note_comment_notification(note_comment, cmt.author) unless cmt.author == @user
          sent_to.add(cmt.author)
        end
      end
    end
  end
end
