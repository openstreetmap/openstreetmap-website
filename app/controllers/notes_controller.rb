class NotesController < ApplicationController

  layout 'site', :only => [:mine]

  before_filter :check_api_readable
  before_filter :authorize_web, :only => [:mine]
  before_filter :setup_user_auth, :only => [:create, :comment]
  before_filter :authorize, :only => [:close, :reopen, :destroy]
  before_filter :require_moderator, :only => [:destroy]
  before_filter :check_api_writable, :only => [:create, :comment, :close, :reopen, :destroy]
  before_filter :require_allow_write_notes, :only => [:create, :comment, :close, :reopen, :destroy]
  before_filter :set_locale
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  ##
  # Return a list of notes in a given area
  def index
    # Figure out the bbox - we prefer a bbox argument but also
    # support the old, deprecated, method with four arguments
    if params[:bbox]
      bbox = BoundingBox.from_bbox_params(params)
    else
      raise OSM::APIBadUserInput.new("No l was given") unless params[:l]
      raise OSM::APIBadUserInput.new("No r was given") unless params[:r]
      raise OSM::APIBadUserInput.new("No b was given") unless params[:b]
      raise OSM::APIBadUserInput.new("No t was given") unless params[:t]

      bbox = BoundingBox.from_lrbt_params(params)
    end

    # Get any conditions that need to be applied
    notes = closed_condition(Note.all)

    # Check that the boundaries are valid
    bbox.check_boundaries

    # Check the the bounding box is not too big
    bbox.check_size(MAX_NOTE_REQUEST_AREA)

    # Find the notes we want to return
    @notes = notes.bbox(bbox).order("updated_at DESC").limit(result_limit).preload(:comments)

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
    # Check the ACLs
    raise OSM::APIAccessDenied if Acl.no_note_comment(request.remote_ip)

    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No lat was given") unless params[:lat]
    raise OSM::APIBadUserInput.new("No lon was given") unless params[:lon]
    raise OSM::APIBadUserInput.new("No text was given") if params[:text].blank?

    # Extract the arguments
    lon = OSM.parse_float(params[:lon], OSM::APIBadUserInput, "lon was not a number")
    lat = OSM.parse_float(params[:lat], OSM::APIBadUserInput, "lat was not a number")
    comment = params[:text]

    # Include in a transaction to ensure that there is always a note_comment for every note
    Note.transaction do
      # Create the note
      @note = Note.create(:lat => lat, :lon => lon)
      raise OSM::APIBadUserInput.new("The note is outside this world") unless @note.in_world?

      # Save the note
      @note.save!

      # Add a comment to the note
      add_comment(@note, comment, "opened")
    end

    # Return a copy of the new note
    respond_to do |format|
      format.xml { render :action => :show }
      format.json { render :action => :show }
    end
  end

  ##
  # Add a comment to an existing note
  def comment
    # Check the ACLs
    raise OSM::APIAccessDenied if Acl.no_note_comment(request.remote_ip)

    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]
    raise OSM::APIBadUserInput.new("No text was given") if params[:text].blank?

    # Extract the arguments
    id = params[:id].to_i
    comment = params[:text]

    # Find the note and check it is valid
    @note = Note.find(id)
    raise OSM::APINotFoundError unless @note
    raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible?
    raise OSM::APINoteAlreadyClosedError.new(@note) if @note.closed?

    # Add a comment to the note
    Note.transaction do
      add_comment(@note, comment, "commented")
    end

    # Return a copy of the updated note
    respond_to do |format|
      format.xml { render :action => :show }
      format.json { render :action => :show }
    end
  end

  ##
  # Close a note
  def close
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Extract the arguments
    id = params[:id].to_i
    comment = params[:text]

    # Find the note and check it is valid
    @note = Note.find_by_id(id)
    raise OSM::APINotFoundError unless @note
    raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible?
    raise OSM::APINoteAlreadyClosedError.new(@note) if @note.closed?

    # Close the note and add a comment
    Note.transaction do
      @note.close

      add_comment(@note, comment, "closed")
    end

    # Return a copy of the updated note
    respond_to do |format|
      format.xml { render :action => :show }
      format.json { render :action => :show }
    end
  end 

  ##
  # Reopen a note
  def reopen
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Extract the arguments
    id = params[:id].to_i
    comment = params[:text]

    # Find the note and check it is valid
    @note = Note.find_by_id(id)
    raise OSM::APINotFoundError unless @note
    raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible? or @user.moderator?
    raise OSM::APINoteAlreadyOpenError.new(@note) unless @note.closed? or not @note.visible?

    # Reopen the note and add a comment
    Note.transaction do
      @note.reopen

      add_comment(@note, comment, "reopened")
    end

    # Return a copy of the updated note
    respond_to do |format|
      format.xml { render :action => :show }
      format.json { render :action => :show }
    end
  end 

  ##
  # Get a feed of recent notes and comments
  def feed
    # Get any conditions that need to be applied
    notes = closed_condition(Note.all)

    # Process any bbox
    if params[:bbox]
      bbox = BoundingBox.from_bbox_params(params)

      bbox.check_boundaries
      bbox.check_size(MAX_NOTE_REQUEST_AREA)

      notes = notes.bbox(bbox)
    end

    # Find the comments we want to return
    @comments = NoteComment.where(:note_id => notes).order("created_at DESC").limit(result_limit).preload(:note)

    # Render the result
    respond_to do |format|
      format.rss
    end
  end

  ##
  # Read a note
  def show
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Find the note and check it is valid
    @note = Note.find(params[:id])
    raise OSM::APINotFoundError unless @note
    raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible?

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
  def destroy
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No id was given") unless params[:id]

    # Extract the arguments
    id = params[:id].to_i
    comment = params[:text]

    # Find the note and check it is valid
    @note = Note.find(id)
    raise OSM::APINotFoundError unless @note
    raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible?

    # Mark the note as hidden
    Note.transaction do
      @note.status = "hidden"
      @note.save

      add_comment(@note, comment, "hidden", false)
    end

    # Return a copy of the updated note
    respond_to do |format|
      format.xml { render :action => :show }
      format.json { render :action => :show }
    end
  end

  ##
  # Return a list of notes matching a given string
  def search
    # Check the arguments are sane
    raise OSM::APIBadUserInput.new("No query string was given") unless params[:q]

    # Get any conditions that need to be applied
    @notes = closed_condition(Note.all)
    @notes = @notes.joins(:comments).where("to_tsvector('english', note_comments.body) @@ plainto_tsquery('english', ?)", params[:q])

    # Find the notes we want to return
    @notes = @notes.order("updated_at DESC").limit(result_limit).preload(:comments)

    # Render the result
    respond_to do |format|
      format.rss { render :action => :index }
      format.xml { render :action => :index }
      format.json { render :action => :index }
      format.gpx { render :action => :index }
    end
  end

  ##
  # Display a list of notes by a specified user
  def mine
    if params[:display_name] 
      if @this_user = User.active.find_by_display_name(params[:display_name])
        @title =  t 'note.mine.title', :user => @this_user.display_name 
        @heading =  t 'note.mine.heading', :user => @this_user.display_name 
        @description = t 'note.mine.subheading', :user => render_to_string(:partial => "user", :object => @this_user)
        @page = (params[:page] || 1).to_i 
        @page_size = 10
        @notes = @this_user.notes.order("updated_at DESC, id").uniq.offset((@page - 1) * @page_size).limit(@page_size).preload(:comments => :author).to_a
      else
        @title = t 'user.no_such_user.title' 
        @not_found_user = params[:display_name] 

        render :template => 'user/no_such_user', :status => :not_found 
      end 
    end
  end

private 
  #------------------------------------------------------------ 
  # utility functions below. 
  #------------------------------------------------------------   
 
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
    if params[:limit]
      if params[:limit].to_i > 0 and params[:limit].to_i <= 10000
        params[:limit].to_i
      else
        raise OSM::APIBadUserInput.new("Note limit must be between 1 and 10000")
      end
    else
      100
    end
  end

  ##
  # Generate a condition to choose which bugs we want based
  # on their status and the user's request parameters
  def closed_condition(notes)
    if params[:closed]
      closed_since = params[:closed].to_i
    else
      closed_since = 7
    end
	
    if closed_since < 0
      notes = notes.where("status != 'hidden'")
    elsif closed_since > 0
      notes = notes.where("(status = 'open' OR (status = 'closed' AND closed_at > '#{Time.now - closed_since.days}'))")
    else
      notes = notes.where("status = 'open'")
    end

    return notes
  end

  ##
  # Add a comment to a note
  def add_comment(note, text, event, notify = true)
    attributes = { :visible => true, :event => event, :body => text }

    if @user  
      attributes[:author_id] = @user.id
    else  
      attributes[:author_ip] = request.remote_ip
    end

    comment = note.comments.create(attributes)

    note.comments.map { |c| c.author }.uniq.each do |user|
      if notify and user and user != @user
        Notifier.note_comment_notification(comment, user).deliver
      end
    end
  end
end
