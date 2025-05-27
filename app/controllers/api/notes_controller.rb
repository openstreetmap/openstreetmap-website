module Api
  class NotesController < ApiController
    include QueryMethods

    before_action :check_api_writable, :only => [:create, :update, :comment, :close, :reopen, :destroy]
    before_action :setup_user_auth, :only => [:create, :show]
    before_action :authorize, :only => [:update, :close, :reopen, :destroy, :comment]

    authorize_resource

    before_action :set_locale
    before_action :set_request_formats, :except => [:feed]

    ##
    # Return a list of notes in a given area
    def index
      # Figure out the bbox - we prefer a bbox argument but also
      # support the old, deprecated, method with four arguments
      if params[:bbox]
        bbox = BoundingBox.from_bbox_params(params)
      elsif params[:l] && params[:r] && params[:b] && params[:t]
        bbox = BoundingBox.from_lrbt_params(params)
      else
        raise OSM::APIBadUserInput, "The parameter bbox is required"
      end

      # Get any conditions that need to be applied
      notes = closed_condition(Note.all)

      # Check that the boundaries are valid
      bbox.check_boundaries

      # Check the the bounding box is not too big
      bbox.check_size(Settings.max_note_request_area)
      @min_lon = bbox.min_lon
      @min_lat = bbox.min_lat
      @max_lon = bbox.max_lon
      @max_lat = bbox.max_lat

      # Find the notes we want to return
      notes = notes.bbox(bbox).order("updated_at DESC")
      notes = query_limit(notes)
      @notes = notes.preload(:comments)

      # Render the result
      respond_to do |format|
        format.rss
        format.xml
        format.json
        format.gpx
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
    # Create a new note
    def create
      # Check the ACLs
      raise OSM::APIAccessDenied if current_user.nil? && Acl.no_note_comment(request.remote_ip)

      # Creates and initializes new note object from passed parameters
      @note = Note.from_params(params, author_info)

      # Include in a transaction to ensure that there is always a note_comment for every note
      Note.transaction do
        # Saves the note without the history
        @note.save_without_history!

        # Adds opening comment (description) to the note
        note_comment = add_comment(@note, @note.description)

        # Saves the note's history
        @note.save_history!(@note.created_at, author_info, note_comment.id, "opened")

        # Notify subscribers about new event and update list of subscribers
        notify_and_update_subscribers(@note, "opened", @note.description)
      end

      # Return a copy of the new note
      respond_to do |format|
        format.xml { render :action => :show }
        format.json { render :action => :show }
      end
    end

    ##
    # Update an existing note
    def update
      # Check the ACLs
      raise OSM::APIAccessDenied if current_user.nil? && Acl.no_note_comment(request.remote_ip)

      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      # Extract the arguments
      id = params[:id].to_i
      comment = params[:comment].presence || ""

      # Find the note, check it is valid and update from passed parameters
      Note.transaction do
        @note = Note.lock.find_by(:id => id)
        raise OSM::APINotFoundError unless @note
        raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible?
        raise OSM::APINoteAlreadyClosedError, @note if @note.closed?

        # Update note from params
        @note.update_from_params(params, author_info)

        # Saves the note without the history
        @note.save_without_history!

        if comment.present?
          # Adds closing comment to the note
          note_comment = add_comment(@note, comment)

          # Saves the note's history
          @note.save_history!(@note.updated_at, author_info, note_comment.id, "updated")
        else
          # Saves the note's history
          @note.save_history!(@note.updated_at, author_info, NoteComment.next_id, "updated")
        end

        # Notify subscribers about new event and update list of subscribers
        notify_and_update_subscribers(@note, "updated", comment)
      end

      # Return a copy of the updated note
      respond_to do |format|
        format.xml { render :action => :show }
        format.json { render :action => :show }
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
      Note.transaction do
        @note = Note.lock.find(id)
        raise OSM::APINotFoundError unless @note
        raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible?

        # Hide the note
        @note.hide

        # Saves the note without the history
        @note.save_without_history!

        if comment.present?
          # Adds hiding comment to the note
          note_comment = add_comment(@note, comment)

          # Saves the note's history
          @note.save_history!(@note.updated_at, author_info, note_comment.id, "hidden")
        else
          # Saves the note's history
          @note.save_history!(@note.updated_at, author_info, NoteComment.next_id, "hidden")
        end

        # Notify subscribers about new event and update list of subscribers
        notify_and_update_subscribers(@note, "hidden", comment, :notify => false)
      end

      # Return a copy of the updated note
      respond_to do |format|
        format.xml { render :action => :show }
        format.json { render :action => :show }
      end
    end

    ##
    # Add a comment to an existing note
    def comment
      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]
      raise OSM::APIBadUserInput, "No text was given" if params[:text].blank?

      # Extract the arguments
      id = params[:id].to_i
      comment = params[:text]

      # Find the note and check it is valid
      Note.transaction do
        @note = Note.lock.find(id)
        raise OSM::APINotFoundError unless @note
        raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible?
        raise OSM::APINoteAlreadyClosedError, @note if @note.closed?

        # Adds a comment to the note
        add_comment(@note, comment)

        # Notify subscribers about new event and update list of subscribers
        notify_and_update_subscribers(@note, "commented", comment)
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
      Note.transaction do
        @note = Note.lock.find_by(:id => id)
        raise OSM::APINotFoundError unless @note
        raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible?
        raise OSM::APINoteAlreadyClosedError, @note if @note.closed?

        # Close the note
        @note.close

        # Saves the note without the history
        @note.save_without_history!

        if comment.present?
          # Adds closing comment to the note
          note_comment = add_comment(@note, comment)

          # Saves the note's history
          @note.save_history!(@note.closed_at, author_info, note_comment.id, "closed")
        else
          # Saves the note's history
          @note.save_history!(@note.closed_at, author_info, NoteComment.next_id, "closed")
        end

        # Notify subscribers about new event and update list of subscribers
        notify_and_update_subscribers(@note, "closed", comment)
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
      Note.transaction do
        @note = Note.lock.find_by(:id => id)
        raise OSM::APINotFoundError unless @note
        raise OSM::APIAlreadyDeletedError.new("note", @note.id) unless @note.visible? || current_user.moderator?
        raise OSM::APINoteAlreadyOpenError, @note unless @note.closed? || !@note.visible?

        # Reopen the note
        @note.reopen

        # Saves the note without the history
        @note.save_without_history!

        if comment.present?
          # Adds reopening comment to the note
          note_comment = add_comment(@note, comment)

          # Saves the note's history
          @note.save_history!(@note.updated_at, author_info, note_comment.id, "reopened")
        else
          # Saves the note's history
          @note.save_history!(@note.updated_at, author_info, NoteComment.next_id, "reopened")
        end

        # Notify subscribers about new event and update list of subscribers
        notify_and_update_subscribers(@note, "reopened", comment)
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
      notes = bbox_condition(notes)

      # Find the comments we want to return
      @comments = CompositeNoteComment.where(:note => notes)
                                      .order(:created_at => :desc)
      @comments = query_limit(@comments)
      @comments = @comments.preload(:author, :note => { :comments => :author })

      # Render the result
      respond_to do |format|
        format.rss
      end
    end

    ##
    # Return a list of notes matching a given string
    def search
      # Get the initial set of notes
      @notes = closed_condition(Note.all)
      @notes = bbox_condition(@notes)

      # Add any user filter
      user = query_conditions_user_value
      @notes = @notes.joins(:comments).where(:composite_note_comments => { :author_id => user }) if user

      # Add any text filter
      if params[:q]
        comments_query = "to_tsvector('english', composite_note_comments.body) @@ plainto_tsquery('english', ?)"
        notes_query = "to_tsvector('english', notes.description) @@ plainto_tsquery('english', ?)"
        @notes = @notes.joins(:comments)
                       .where("#{comments_query} OR #{notes_query}", params[:q], params[:q])
      end

      # Add any date filter
      time_filter_property = if params[:sort] == "updated_at"
                               :updated_at
                             else
                               :created_at
                             end
      @notes = query_conditions_time(@notes, time_filter_property)

      # Choose the sort order
      @notes = if params[:sort] == "created_at"
                 if params[:order] == "oldest"
                   @notes.order("created_at ASC")
                 else
                   @notes.order("created_at DESC")
                 end
               else
                 if params[:order] == "oldest"
                   @notes.order("updated_at ASC")
                 else
                   @notes.order("updated_at DESC")
                 end
               end

      # Find the notes we want to return
      @notes = query_limit(@notes.distinct)
      @notes = @notes.preload(:comments)

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
    # Generate a condition to choose which notes we want based
    # on their status and the user's request parameters
    def closed_condition(notes)
      closed_since = if params[:closed]
                       params[:closed].to_i.days
                     else
                       Note::DEFAULT_FRESHLY_CLOSED_LIMIT
                     end

      if closed_since.negative?
        notes.where.not(:status => "hidden")
      elsif closed_since.positive?
        notes.where(:status => "open")
             .or(notes.where(:status => "closed")
                      .where(notes.arel_table[:closed_at].gt(Time.now.utc - closed_since)))
      else
        notes.where(:status => "open")
      end
    end

    ##
    # Generate a condition to choose which notes we want based
    # on the user's bounding box request parameters
    def bbox_condition(notes)
      if params[:bbox]
        bbox = BoundingBox.from_bbox_params(params)

        bbox.check_boundaries
        bbox.check_size(Settings.max_note_request_area)

        @min_lon = bbox.min_lon
        @min_lat = bbox.min_lat
        @max_lon = bbox.max_lon
        @max_lat = bbox.max_lat

        notes.bbox(bbox)
      else
        notes
      end
    end

    ##
    # Get author's information (for logged in users - user_id, for logged out users - IP address)
    def author_info
      if current_user
        { :user_id => current_user.id }
      else
        { :user_ip => request.remote_ip }
      end
    end

    ##
    # Add a comment to a note
    def add_comment(note, text)
      attributes = { :note_id => note.id, :visible => true, :body => text }

      # Get note comment's author info (for logged in users - user_id, for logged out users - IP address)
      note_comment_author_info = author_info

      if note_comment_author_info[:user_ip].nil?
        attributes[:author_id] = note_comment_author_info[:user_id]
      else
        attributes[:author_ip] = note_comment_author_info[:user_ip]
      end

      # Create new note comment with passed attributes
      NoteComment.create!(attributes)
    end

    ##
    # Notify note subscribers about new event and update list of subscribers
    def notify_and_update_subscribers(note, event, event_text, notify: true)
      if notify
        note.subscribers.visible.each do |user|
          UserMailer.note_comment_notification(note, event, current_user, event_text, user).deliver_later if current_user != user
        end
      end

      NoteSubscription.find_or_create_by(:note => note, :user => current_user) if current_user
    end
  end
end
