class NoteController < ApplicationController

  layout 'site', :only => [:mine]

  before_filter :check_api_readable
  before_filter :authorize_web, :only => [:create, :close, :update, :delete, :mine]
  before_filter :check_api_writable, :only => [:create, :close, :update, :delete]
  before_filter :set_locale, :only => [:mine]
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  # Help methods for checking boundary sanity and area size
  include MapBoundary

  ##
  # Return a list of notes in a given area
  def list
    # Figure out the bbox - we prefer a bbox argument but also
    # support the old, deprecated, method with four arguments
    if params[:bbox]
      raise OSM::APIBadUserInput.new("Invalid bbox") unless params[:bbox].count(",") == 3

      bbox = params[:bbox].split(",")
    else
      raise OSM::APIBadUserInput.new("No l was given") unless params[:l]
      raise OSM::APIBadUserInput.new("No r was given") unless params[:r]
      raise OSM::APIBadUserInput.new("No b was given") unless params[:b]
      raise OSM::APIBadUserInput.new("No t was given") unless params[:t]

      bbox = [ params[:l], params[:b], params[:r], params[:t] ]
    end

    # Get the sanitised boundaries
    @min_lon, @min_lat, @max_lon, @max_lat = sanitise_boundaries(bbox)

    # Get any conditions that need to be applied
    conditions = closed_condition

    # Check that the boundaries are valid
    check_boundaries(@min_lon, @min_lat, @max_lon, @max_lat, MAX_NOTE_REQUEST_AREA)

    # Find the notes we want to return
    @notes = Note.find_by_area(@min_lat, @min_lon, @max_lat, @max_lon,
                               :include => :comments, 
                               :conditions => conditions,
                               :order => "updated_at DESC", 
                               :limit => result_limit)

    # Render the result
    respond_to do |format|
      format.rss
      format.xml
      format.json
      format.gpx
    end
  end

  ##
  # Create a new note
  def create
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No lat was given") unless params[:lat]
    raise OSM::APIBadUserInput.new("No lon was given") unless params[:lon]
    raise OSM::APIBadUserInput.new("No text was given") unless params[:text]

    # Extract the arguments
    lon = params[:lon].to_f
    lat = params[:lat].to_f
    comment = params[:text]
    name = params[:name]

    # Include in a transaction to ensure that there is always a note_comment for every note
    Note.transaction do
      # Create the note
      @note = Note.create(:lat => lat, :lon => lon)
      raise OSM::APIBadUserInput.new("The note is outside this world") unless @note.in_world?

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

      # Save the note
      @note.save

      # Add a comment to the note
      add_comment(@note, comment, name, "opened")
    end

    # Send an OK response
    render_ok
  end

  ##
  # Add a comment to an existing note
  def update
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]
    raise OSM::APIBadUserInput.new("No text was given") unless params[:text]

    # Extract the arguments
    id = params[:id].to_i
    comment = params[:text]
    name = params[:name] or "NoName"

    # Find the note and check it is valid
    note = Note.find(id)
    raise OSM::APINotFoundError unless note
    raise OSM::APIAlreadyDeletedError unless note.visible?

    # Add a comment to the note
    Note.transaction do
      add_comment(note, comment, name, "commented")
    end

    # Send an OK response
    render_ok
  end

  ##
  # Close a note
  def close
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Extract the arguments
    id = params[:id].to_i
    name = params[:name]

    # Find the note and check it is valid
    note = Note.find_by_id(id)
    raise OSM::APINotFoundError unless note
    raise OSM::APIAlreadyDeletedError unless note.visible?

    # Close the note and add a comment
    Note.transaction do
      note.close

      add_comment(note, nil, name, "closed")
    end

    # Send an OK response
    render_ok
  end 

  ##
  # Get a feed of recent notes and comments
  def rss
    # Get any conditions that need to be applied
    conditions = closed_condition

    # Process any bbox
    if params[:bbox]
      raise OSM::APIBadUserInput.new("Invalid bbox") unless params[:bbox].count(",") == 3

      @min_lon, @min_lat, @max_lon, @max_lat = sanitise_boundaries(params[:bbox].split(','))

      check_boundaries(@min_lon, @min_lat, @max_lon, @max_lat, MAX_NOTE_REQUEST_AREA)

      conditions = cond_merge conditions, [OSM.sql_for_area(@min_lat, @min_lon, @max_lat, @max_lon, "notes.")]
    end

    # Find the comments we want to return
    @comments = NoteComment.find(:all, 
                                 :conditions => conditions,
                                 :order => "created_at DESC",
                                 :limit => result_limit,
                                 :joins => :note, 
                                 :include => :note)

    # Render the result
    respond_to do |format|
      format.rss
    end
  end

  ##
  # Read a note
  def read
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Find the note and check it is valid
    @note = Note.find(params[:id])
    raise OSM::APINotFoundError unless @note
    raise OSM::APIAlreadyDeletedError unless @note.visible?
    
    # Render the result
    respond_to do |format|
      format.xml
      format.rss
      format.json
      format.gpx
    end
  end

  ##
  # Delete (hide) a note
  def delete
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Extract the arguments
    id = params[:id].to_i
    name = params[:name]

    # Find the note and check it is valid
    note = Note.find(id)
    raise OSM::APINotFoundError unless note
    raise OSM::APIAlreadyDeletedError unless note.visible?

    # Mark the note as hidden
    Note.transaction do
      note.status = "hidden"
      note.save

      add_comment(note, nil, name, "hidden")
    end

    # Render the result
    render :text => "ok\n", :content_type => "text/html" 
  end

  ##
  # Return a list of notes matching a given string
  def search
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No query string was given") unless params[:q]

    # Get any conditions that need to be applied
    conditions = closed_condition
    conditions = cond_merge conditions, ['note_comments.body ~ ?', params[:q]]
	
    # Find the notes we want to return
    @notes = Note.find(:all, 
                       :conditions => conditions,
                       :order => "updated_at DESC",
                       :limit => result_limit,
                       :joins => :comments,
                       :include => :comments)

    # Render the result
    respond_to do |format|
      format.html { render :action => :list, :format => :rjs, :content_type => "text/javascript"}
      format.rss { render :action => :list }
      format.js
      format.xml { render :action => :list }
      format.json { render :action => :list }
      format.gpx { render :action => :list }
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

  ##
  # Render an OK response
  def render_ok
    if params[:format] == "js"
      render :text => "osbResponse();", :content_type => "text/javascript" 
    else
      render :text => "ok " + @note.id.to_s + "\n", :content_type => "text/plain" if @note
      render :text => "ok\n", :content_type => "text/plain" unless @note
    end
  end

  ##
  # Get the maximum number of results to return
  def result_limit
    if params[:limit] and params[:limit].to_i > 0 and params[:limit].to_i < 10000
      params[:limit].to_i
    else
      100
    end
  end

  ##
  # Generate a condition to choose which bugs we want based
  # on their status and the user's request parameters
  def closed_condition
    if params[:closed]
      closed_since = params[:closed].to_i
    else
      closed_since = 7
    end
	
    if closed_since < 0
      conditions = ["status != 'hidden'"]
    elsif closed_since > 0
      conditions = ["(status = 'open' OR (status = 'closed' AND closed_at > '#{Time.now - closed_since.days}'))"]
    else
      conditions = ["status = 'open'"]
    end

    return conditions
  end

  ##
  # Add a comment to a note
  def add_comment(note, text, name, event)
    name = "NoName" if name.nil?

    attributes = { :visible => true, :event => event, :body => text }

    if @user  
      attributes[:author_id] = @user.id
      attributes[:author_name] = @user.display_name
    else  
      attributes[:author_ip] = request.remote_ip
      attributes[:author_name] = name + " (a)"
    end

    note.comments.create(attributes)

    note.comments.map { |c| c.author }.uniq.each do |user|
      if user and user != @user
        Notifier.deliver_note_comment_notification(comment, user)
      end
    end
  end
end
