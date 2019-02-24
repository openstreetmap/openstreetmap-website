module Api
  class NotesController < ApplicationController
    layout "site", :only => [:mine]

    skip_before_action :verify_authenticity_token
    before_action :check_api_readable
    before_action :setup_user_auth, :only => [:create, :comment, :show]
    before_action :authorize, :only => [:close, :reopen, :destroy]
    before_action :api_deny_access_handler

    authorize_resource

    before_action :check_api_writable, :only => [:create, :comment, :close, :reopen, :destroy]
    before_action :set_locale
    around_action :api_call_handle_error, :api_call_timeout

    ##
    # Return a list of notes in a given area
    def index
      # Figure out the bbox - we prefer a bbox argument but also
      # support the old, deprecated, method with four arguments
      if params[:bbox]
        bbox = BoundingBox.from_bbox_params(params)
      else
        raise OSM::APIBadUserInput, "No l was given" unless params[:l]
        raise OSM::APIBadUserInput, "No r was given" unless params[:r]
        raise OSM::APIBadUserInput, "No b was given" unless params[:b]
        raise OSM::APIBadUserInput, "No t was given" unless params[:t]

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
      raise OSM::APIAccessDenied if current_user.nil? && Acl.no_note_comment(request.remote_ip)

      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No lat was given" unless params[:lat]
      raise OSM::APIBadUserInput, "No lon was given" unless params[:lon]
      raise OSM::APIBadUserInput, "No text was given" if params[:text].blank?

      # Extract the arguments
      lon = OSM.parse_float(params[:lon], OSM::APIBadUserInput, "lon was not a number")
      lat = OSM.parse_float(params[:lat], OSM::APIBadUserInput, "lat was not a number")
      comment = params[:text]

      # Include in a transaction to ensure that there is always a note_comment for every note
      Note.transaction do
        # Create the note
        @note = Note.create(:lat => lat, :lon => lon)
        raise OSM::APIBadUserInput, "The note is outside this world" unless @note.in_world?

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
      raise OSM::APIAccessDenied if current_user.nil? && Acl.no_note_comment(request.remote_ip)

      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]
      raise OSM::APIBadUserInput, "No text was given" if params[:text].blank?

      # Extract the arguments
      id = params[:id].to_i
      comment = params[:text]

      # Find the note and check it is valid
      @note = Note.find(id)
      raise OSM::APINotFoundError unless @note
      raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible?
      raise OSM::APINoteAlreadyClosedError, @note if @note.closed?

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
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      # Extract the arguments
      id = params[:id].to_i
      comment = params[:text]

      # Find the note and check it is valid
      @note = Note.find_by(:id => id)
      raise OSM::APINotFoundError unless @note
      raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible?
      raise OSM::APINoteAlreadyClosedError, @note if @note.closed?

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
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      # Extract the arguments
      id = params[:id].to_i
      comment = params[:text]

      # Find the note and check it is valid
      @note = Note.find_by(:id => id)
      raise OSM::APINotFoundError unless @note
      raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible? || current_user.moderator?
      raise OSM::APINoteAlreadyOpenError, @note unless @note.closed? || !@note.visible?

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
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      # Find the note and check it is valid
      @note = Note.find(params[:id])
      raise OSM::APINotFoundError unless @note
      raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible? || current_user&.moderator?

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
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

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
      # Get the initial set of notes
      @notes = closed_condition(Note.all)

      # Add any user filter
      if params[:display_name] || params[:user]
        if params[:display_name]
          @user = User.find_by(:display_name => params[:display_name])

          raise OSM::APIBadUserInput, "User #{params[:display_name]} not known" unless @user
        else
          @user = User.find_by(:id => params[:user])

          raise OSM::APIBadUserInput, "User #{params[:user]} not known" unless @user
        end

        @notes = @notes.joins(:comments).where(:note_comments => { :author_id => @user })
      end

      # Add any text filter
      @notes = @notes.joins(:comments).where("to_tsvector('english', note_comments.body) @@ plainto_tsquery('english', ?)", params[:q]) if params[:q]

      # Add any date filter
      if params[:from]
        begin
          from = Time.parse(params[:from])
        rescue ArgumentError
          raise OSM::APIBadUserInput, "Date #{params[:from]} is in a wrong format"
        end

        begin
          to = if params[:to]
                 Time.parse(params[:to])
               else
                 Time.now
               end
        rescue ArgumentError
          raise OSM::APIBadUserInput, "Date #{params[:to]} is in a wrong format"
        end

        @notes = @notes.where(:created_at => from..to)
      end

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

    private

    #------------------------------------------------------------
    # utility functions below.
    #------------------------------------------------------------

    ##
    # Get the maximum number of results to return
    def result_limit
      if params[:limit]
        if params[:limit].to_i.positive? && params[:limit].to_i <= 10000
          params[:limit].to_i
        else
          raise OSM::APIBadUserInput, "Note limit must be between 1 and 10000"
        end
      else
        100
      end
    end

    ##
    # Generate a condition to choose which notes we want based
    # on their status and the user's request parameters
    def closed_condition(notes)
      closed_since = if params[:closed]
                       params[:closed].to_i
                     else
                       7
                     end

      if closed_since.negative?
        notes.where.not(:status => "hidden")
      elsif closed_since.positive?
        notes.where(:status => "open")
             .or(notes.where(:status => "closed")
                      .where(notes.arel_table[:closed_at].gt(Time.now - closed_since.days)))
      else
        notes.where(:status => "open")
      end
    end

    ##
    # Add a comment to a note
    def add_comment(note, text, event, notify = true)
      attributes = { :visible => true, :event => event, :body => text }

      if current_user
        attributes[:author_id] = current_user.id
      else
        attributes[:author_ip] = request.remote_ip
      end

      comment = note.comments.create!(attributes)

      note.comments.map(&:author).uniq.each do |user|
        Notifier.note_comment_notification(comment, user).deliver_later if notify && user && user != current_user && user.visible?
      end
    end
  end
end
